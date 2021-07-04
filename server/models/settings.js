'use strict';

const knex = require('../lib/knex');
const { filterObject } = require('../lib/helpers');
const hasher = require('node-object-hash')();
const shares = require('./shares');
const interoperableErrors = require('../../shared/interoperable-errors');

const allowedKeys = new Set(['adminEmail', 'uaCode', 'mapsApiKey', 'shoutout', 'pgpPassphrase', 'pgpPrivateKey', 'defaultHomepage', 'ssoRoleMapping', 'ssoNamespaceMapping']);
// defaultHomepage is used as a default to list.homepage - if the list.homepage is not filled in

function hash(entity) {
    return hasher.hash(filterObject(entity, allowedKeys));
}

async function get(context, keyOrKeys) {
    shares.enforceGlobalPermission(context, 'manageSettings');

    let keys;
    if (!keyOrKeys) {
        keys = [...allowedKeys.values()];
    } else if (!Array.isArray(keyOrKeys)) {
        keys = [ keys ];
    } else {
        keys = keyOrKeys;
    }

    const rows = await knex('settings').select(['key', 'value']).whereIn('key', keys);

    const settings = {};
    for (const row of rows) {
        settings[row.key] = row.value;
    }

    if (!Array.isArray(keyOrKeys) && keyOrKeys) {
        return settings[keyOrKeys];
    } else {
        return settings;
    }
}

async function set(context, data) {
    shares.enforceGlobalPermission(context, 'manageSettings');

    // Validate SSO settings so we don't accidentally break login
    // 1. Should be valid JSON
    JSON.parse(data.ssoRoleMapping);
    let namespaceMapping = JSON.parse(data.ssoNamespaceMapping);

    // 2. Each key in namespace mapping should be a valid namespace
    const rows = (await knex('namespaces').select(['namespaces.name'])).map(packet => packet.name)
    for (const key in namespaceMapping) {
        if (!rows.includes(key)) {
            throw new interoperableErrors.NamespaceNotFoundError(`SSO: Namespace ${key} doesn't exist`)
        }
    }

    for (const key in data) {
        if (allowedKeys.has(key)) {
            const value = data[key];
            try {
                await knex('settings').insert({key, value});
            } catch (err) {
                await knex('settings').where('key', key).update('value', value);
            }
        }
    }

    // FIXME - recreate mailers, notify senders to recreate the mailers
}

module.exports.hash = hash;
module.exports.get = get;
module.exports.set = set;

