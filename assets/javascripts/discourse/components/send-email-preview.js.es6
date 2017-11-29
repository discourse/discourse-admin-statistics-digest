import Ember from 'ember';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import Config from 'discourse/plugins/discourse-admin-statistics-digest/discourse/mixins/config';
import Helper from 'discourse/plugins/discourse-admin-statistics-digest/discourse/mixins/helper';

export default Ember.Component.extend(Config, Helper, {
  classNames: ['send-email-preview'],

  actions: {
    submit() {
      ajax(`${this.baseUrl}/preview.json`)
        .then(() => this._showNotice()).catch(popupAjaxError);
    },
  }
});
