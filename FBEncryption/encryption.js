function generate_key_pair(phrase) {
    var bits = 2048;
    setTimeout(function() {
               var rsa_key = cryptico.generateRSAKey(phrase, bits);
               my_private_key = JSON.stringify(rsa_key);
               my_public_key = cryptico.publicKeyString(rsa_key);
               }, 0);
}

function encrypt(message, public_key) {
    return cryptico.encrypt(message, public_key).cipher;
}

function decrypt(cipher, private_key) {
    return cryptico.decrypt(message, private_key).plaintext;
}

function cast_to_rsa_key(rsa_key) {
    // cast to BigInteger
    rsa_key.n.__proto__ = BigInteger.prototype;
    rsa_key.d.__proto__ = BigInteger.prototype;
    rsa_key.p.__proto__ = BigInteger.prototype;
    rsa_key.q.__proto__ = BigInteger.prototype;
    rsa_key.dmp1.__proto__ = BigInteger.prototype;
    rsa_key.dmq1.__proto__ = BigInteger.prototype;
    rsa_key.coeff.__proto__ = BigInteger.prototype;
    rsa_key.__proto__ = RSAKey.prototype;
    return rsa_key;
}