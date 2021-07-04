'use strict';

import React, {Component} from 'react';
import PropTypes from 'prop-types';
import {withTranslation} from './lib/i18n';
import {requiresAuthenticatedUser} from './lib/page';
import {withComponentMixins} from "./lib/decorator-helpers";
import mailtrainConfig from 'mailtrainConfig';
import Countdown from 'react-countdown';

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

        // Random component
        const Completionist = () => <h3>🎉HAPPY THON WEEKEND!!!!🥳</h3>;

        const s = (count, message) => count > 0 ? `${count} ${message}${count == 1 ? '' : 's'}` : '';
        const sComma = (count, message) => count > 0 ? s(count, message) + ', ' : '';

        // Renderer callback with condition
        const renderer = ({ days, hours, minutes, seconds, completed }) => {
        if (completed) {
            // Render a completed state
            return <Completionist />;
        } else {
            // Render a countdown
            return <h3>{sComma(days, 'day')}{sComma(hours, 'hour')}{sComma(minutes, 'minute')}{s(seconds, 'second')}</h3>;
        }
        };

        return (
            <div>

                <h2>{t('THON Mailtrain')}</h2>
                <div>{t('Welcome to THON\'s fork of Mailtrain, home of THON\'s biggest newsletters.')}</div>
                <div>{t('For support, see ')}<a href='https://wiki.thon.org/display/MAIL/Mailtrain'>the Mailtrain User Guide on the THON Wiki.</a></div>
                <p>{mailtrainConfig.shoutout}</p>
                <hr/>
                <h2>THON Weekend Countdown</h2>
                <Countdown date={'2022-02-18 17:00'} renderer={renderer} />
            </div>
        );
    }
}