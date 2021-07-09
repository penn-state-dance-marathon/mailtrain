'use strict';

const config = require('../config');
const settings = require('../../models/settings');
const contextHelpers = require('../context-helpers');

const log = require('../log');


const entitySettings = require('../entity-settings');
const { assign, listByUserDTAjax } = require('../../models/shares');
const knex = require('../knex');

async function getMailtrainRoleFromKeycloakRoles(keycloakRoles) {
    const settings = await settings.get(contextHelpers.getAdminContext(), ["ssoRoleMapping"]);
    const roleMapping = JSON.parse(settings.ssoRoleMapping);
    for (const mailtrainRole in roleMapping) {
        // Check if the intersection of the roles in the settings and the user's role is nonempty
        // If so, give them that role.
        // Theoretically, the user could fall under multiple roles, so we just naively choose the first one.
        if (roleMapping[mailtrainRole].filter(keycloakRole => keycloakRoles.includes(keycloakRole)).length > 0) {
            return mailtrainRole;
        }
    }
    return config.keycloak.newUserRole;
}

async function getNamespacesFromKeycloakRoles(keycloakRoles) {
    let result = {};
    const settingsObj = await settings.get(contextHelpers.getAdminContext(), ["ssoNamespaceMapping"]);
    const namespaceMapping = JSON.parse(settingsObj.ssoNamespaceMapping);
    for (const namespace in namespaceMapping) {
        for (const role in namespaceMapping[namespace]) {
            if (namespaceMapping[namespace][role].filter(keycloakRole => keycloakRoles.includes(keycloakRole)).length > 0) {
                result[namespace] = role;
            }
        }
    }
    return result;
}

async function shareNamespacesWithUser(user, keycloakRoles) {
    const newNamespaces = await getNamespacesFromKeycloakRoles(keycloakRoles);

    const entityType = entitySettings.getEntityType('namespace');
    const oldNamespaces = await knex(entityType.sharesTable).where({user: user.id})
        .innerJoin('namespaces', 'namespaces.id', `${entityType.sharesTable}.entity`)
        .select('namespaces.name', `${entityType.sharesTable}.role`, `namespaces.id`)

    let sharesToDelete = oldNamespaces.filter(namespace => !Object.keys(newNamespaces).includes(namespace.name));

    for (const shareToDelete of sharesToDelete) {
        await knex(entityType.sharesTable).where({entity: shareToDelete.id, user: user.id}).del();
    }

    for (const namespace in newNamespaces) {
        const namespaceDatabaseObj = await knex('namespaces').where({name: namespace}).select('id').first()
        await assign(contextHelpers.getAdminContext(), 'namespace', namespaceDatabaseObj.id, user.id, newNamespaces[namespace]);
    }
}

module.exports = {
    getMailtrainRoleFromKeycloakRoles,
    getNamespacesFromKeycloakRoles,
    shareNamespacesWithUser
}

