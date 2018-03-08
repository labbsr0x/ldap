import {Meteor} from 'meteor/meteor';
import ldap from 'ldap';

Meteor.startup(() => {

    // testeLdap();

});

const testeLdap = () => {

    console.log("passei aqui");

    const baseDN           = process.env.LDAP_base_dn;
    const user             = process.env.LDAP_user;
    const password         = process.env.LDAP_password;
    const host             = process.env.LDAP_host;
    const port             = process.env.LDAP_port;
    const objectClass      = process.env.LDAP_object_class;
    const searchField      = process.env.LDAP_search_field;
    const searchFilter     = process.env.LDAP_search_filter;
    const searchScope      = process.env.LDAP_search_scope;
    const searchAttributes = process.env.LDAP_search_attributes.split(',');
    const timeout          = process.env.LDAP_timeout;
    const connectTimeout   = process.env.LDAP_connect_timeout;
    const idleTimeout      = process.env.LDAP_idle_timeout;
    const tlsOptions       = process.env.LDAP_tls_options;
    const strictDN         = process.env.LDAP_strict_dn;

    //  const searchAttributes = ['*'];

    const client = ldap.createClient({
        url: `${host}:${port}`,
        timeout,
        tlsOptions,
        connectTimeout,
        idleTimeout,
        strictDN
    });

    client.bind(`uid=${user},${baseDN}`, password, err => {
        console.log("deu merda", err);
        //todo tratamento de erro (Credentials are not valid)
    });

    const opts = {
        filter: `(&(objectclass=${objectClass})(${searchField}=${searchFilter}))`,
        scope: searchScope,
        attributes: searchAttributes
    };

    client.search(baseDN, opts, (err, res) => {

        console.log("deu merda 2", err);

        res.on('searchEntry', function (entry) {
            console.log('entry: ' + JSON.stringify(entry.object));
        });
        res.on('searchReference', function (referral) {
            console.log('referral: ' + referral.uris.join());
        });
        res.on('error', function (err) {
            console.error('error 2365: ' + err.message);
        });
        res.on('end', function (result) {
            console.log('status: ' + result);
            console.log('status: ' + result.status);
        });
    });
};