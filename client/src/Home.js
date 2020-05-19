'use strict';

import React, {Component} from 'react';
import {withTranslation} from './lib/i18n';
import {requiresAuthenticatedUser} from './lib/page';
import {withComponentMixins} from "./lib/decorator-helpers";

@withComponentMixins([
    withTranslation,
    requiresAuthenticatedUser
])
export default class List extends Component {
    constructor(props) {
        super(props);
    }

    render() {
        const t = this.props.t;

        return (
            <div>
                <h2>{t('THON MailTrain')}</h2>
                <div>{t('Welcome to THON\'s fork of MailTrain! There isn\'t much here yet, check back for a fresh UI and support for some of THON\'s biggest newsletters.')}</div>
            </div>
        );
    }
}