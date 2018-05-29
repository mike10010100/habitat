// Copyright (c) 2018 Chef Software Inc. and/or applicable contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//! Modules which can be serialized and deserialized to and from Google Protobufs.
//!
//! The types in the contained modules are largely generated or are new-type wrappers around
//! generated code. All generated code is placed in [`generated`] which comes from Protobuf
//! definition files in the `protocols` directory at the root of the Supervisor crate.
//!
//! # Defining New Protocols
//!
//! A new generated module is created at `protocols::generated::{T}` where `T` is the name of your
//! Protobuf file placed in the `protocols` directory. For example, given the file
//! `protocols/net.proto`, a new Rust module will be placed at `src/generated/net.rs`.
//!
//! Each time a new Protobuf file is added, you will need to update the `generated` module with
//! an entry of the newly generated module. Given the previous example, you will need to add
//! `pub mod net` to the generated module.
//!
//! WARNING: Do not attempt to create a protocol named after a reserved Rust type, such as `mod`,
//!          as this will lead to undefined behaviour.
//!
//! # Generating Protocols
//!
//! Protocol files are generated when the `protocols` feature is passed to Cargo. You can do this
//! by running `cargo build --features protocols`. This command should be run each time a new
//! protocol file is added or anytime one is changed. Generated files are to be committed to
//! version control. Files are generated on your workstation and committed to version control and
//! *not* by a build server intentionally. This is to ensure we have the source available for
//! all protocol files.

extern crate base64;
extern crate bytes;
extern crate futures;
extern crate habitat_core as core;
#[macro_use]
extern crate lazy_static;
#[macro_use]
extern crate log;
extern crate prost;
#[macro_use]
extern crate prost_derive;
extern crate rand;
extern crate serde;
#[macro_use]
extern crate serde_derive;
extern crate tokio;
extern crate tokio_io;

pub mod butterfly;
pub mod codec;
pub mod ctl;
pub mod message;
pub mod net;
pub mod types;

use std::fs::File;
use std::io::Read;
use std::path::{Path, PathBuf};

use rand::Rng;

use net::{ErrCode, NetResult};

// Nane of file containing the CtlGateway secret key.
const CTL_SECRET_FILENAME: &'static str = "CTL_SECRET";
/// Length of characters in CtlGateway secret key.
const CTL_SECRET_LEN: usize = 64;

lazy_static! {
    /// The root path containing all runtime service directories and files
    pub static ref STATE_PATH_PREFIX: PathBuf = {
        Path::new(&*core::fs::FS_ROOT_PATH).join("hab/sup")
    };

    pub static ref DEFAULT_BLDR_URL: String = {
        core::url::default_bldr_url()
    };

    pub static ref DEFAULT_BLDR_CHANNEL: String = {
        core::channel::default()
    };
}

/// Generate a new secret key used for authenticating clients to the `CtlGateway`.
pub fn generate_secret_key(out: &mut String) {
    let mut rng = rand::OsRng::new().unwrap();
    let mut result = vec![0u8; CTL_SECRET_LEN];
    rng.fill_bytes(&mut result);
    *out = base64::encode(&result);
}

/// Read the secret key used to authenticate connections to the `CtlGateway` from disk and write
/// it to the given out buffer. An `Ok` return value of `true` indicates a successful read while
/// `false` indicates the file was not found.
pub fn read_secret_key<T>(sup_root: T, out: &mut String) -> NetResult<bool>
where
    T: AsRef<Path>,
{
    let secret_key_path = sup_root.as_ref().join(CTL_SECRET_FILENAME);
    if secret_key_path.exists() {
        if secret_key_path.is_dir() {
            return Err(net::err(
                ErrCode::Io,
                format!(
                    "Expected file but found directory when reading ctl secret, {}",
                    secret_key_path.display()
                ),
            ));
        }
        File::open(&secret_key_path)
            .and_then(|mut f| f.read_to_string(out))
            .map_err(move |e| {
                net::err(
                    ErrCode::Io,
                    format!(
                        "IoError while reading or writing ctl secret, {}, {}",
                        secret_key_path.display(),
                        e
                    ),
                )
            })?;
        Ok(true)
    } else {
        Ok(false)
    }
}

/// Returns the location of the CtlGateway Secret on disk for the given Supervisor root.
pub fn secret_key_path<T>(sup_root: T) -> PathBuf
where
    T: AsRef<Path>,
{
    sup_root.as_ref().join(CTL_SECRET_FILENAME)
}

pub fn sup_root<T, U>(name: Option<T>, custom_state_path: Option<U>) -> PathBuf
where
    T: AsRef<Path>,
    U: AsRef<Path>,
{
    match custom_state_path {
        Some(ref custom) => custom.as_ref().to_path_buf(),
        None => match name {
            Some(ref name) => STATE_PATH_PREFIX.join(name),
            None => STATE_PATH_PREFIX.join("default"),
        },
    }
}
