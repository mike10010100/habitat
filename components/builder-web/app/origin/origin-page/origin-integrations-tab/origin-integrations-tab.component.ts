// Copyright (c) 2016-2017 Chef Software Inc. and/or applicable contributors
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

import { Component, OnInit } from '@angular/core';
import { AppStore } from '../../../app.store';
import { deleteIntegration, setIntegration } from '../../../actions';
import { MatDialog } from '@angular/material';
import { IntegrationCredentialsFormDialog } from '../integration-credentials-form/integration-credentials-form.dialog';
import { IntegrationDeleteConfirmDialog } from './dialog/integration-delete-confirm/integration-delete-confirm.dialog';
import { fetchIntegrations } from '../../../actions/index';

@Component({
  template: require('./origin-integrations-tab.component.html')
})
export class OriginIntegrationsTabComponent implements OnInit {

  constructor(
    private store: AppStore,
    private credsDialog: MatDialog,
    private confirmDialog: MatDialog
  ) { }

  ngOnInit() {
    this.store.dispatch(fetchIntegrations(this.origin.name, this.token));
  }

  get integrations() {
    return this.store.getState().origins.currentIntegrations.integrations;
  }

  get origin() {
    return this.store.getState().origins.current;
  }

  get originPrivacy() {
    return this.store.getState().origins.current.default_package_visibility;
  }

  get token() {
    return this.store.getState().session.token;
  }

  addIntegration(type: string, name: string): void {
    this.credsDialog
      .open(IntegrationCredentialsFormDialog, {
        data: { type },
        width: '480px'
      })
      .afterClosed()
      .subscribe((result) => {
        if (result) {
          const name = result['name'];
          delete result['name'];
          this.store.dispatch(setIntegration(this.origin.name, result, this.token, type, name));
        }
      });
  }

  deleteIntegration(name, type) {
    this.confirmDialog
      .open(IntegrationDeleteConfirmDialog, { width: '480px' })
      .afterClosed()
      .subscribe(confirmed => {
        if (confirmed) {
          this.store.dispatch(deleteIntegration(this.origin.name, this.token, name, type));
        }
      });
  }
}
