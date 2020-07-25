'use strict';

import React, {Component} from 'react';
import PropTypes from 'prop-types';
import {withTranslation} from './lib/i18n';
import {requiresAuthenticatedUser} from './lib/page';
import {withComponentMixins} from "./lib/decorator-helpers";
import mailtrainConfig from 'mailtrainConfig';

@withComponentMixins([
    withTranslation,
    requiresAuthenticatedUser
])
export default class List extends Component {
    constructor(props) {
        super(props);
    }

    static propTypes = {
    }

    render() {
        const t = this.props.t;

        return (
            <div>

                <h2>{t('THON Mailtrain')}</h2>
                <div>{t('Welcome to THON\'s fork of Mailtrain! There isn\'t much here yet, check back for a fresh UI and support for some of THON\'s biggest newsletters.')}</div>
                <p>{mailtrainConfig.shoutout}</p>

            </div>
        );
    }
}