import { Meteor } from 'meteor/meteor';
import ldap from 'ldap';

Meteor.startup(() => {
  console.log("passei aqui");

    const usuario = 'F1234547';
    const senha =  'suasenha';

    const client = ldap.createClient({
        url: 'ldaps://aplic.ldapbb.bb.com.br:636'
    });

    console.log('haahah');

    const subDn = `ou=usuarios,ou=acesso,o=bb,c=br`;
    const dn = `ou=funcionarios,${subDn}`;

    client.bind(`uid=${usuario},${dn}`, senha, err => {
        console.log("deu merda", err);
    });

    const opts = {
        filter: `(&(objectclass=inetOrgPerson)(uid=${usuario}))`,
        scope: 'sub',
        attributes: ['sn', 'cn', 'mail' ]
    };

    console.log('haahah3');
    client.search(subDn, opts, (err, res) => {

        console.log("deu merda 2", err);

        res.on('searchEntry', function (entry) {
            console.log('entry: ' + JSON.stringify(entry.object));
        });
        res.on('searchReference', function (referral) {
            console.log('referral: ' + referral.uris.join());
        });
        res.on('error', function (err) {
            console.error('error: ' + err.message);
        });
        res.on('end', function (result) {
            console.log('status: ' + result);
            console.log('status: ' + result.status);
        });
    });

});

