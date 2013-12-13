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

function derive_public(my_private_key){
    var G = getSECCurveByName("secp256r1").getG();
    var a = new BigInteger(my_private_key);
    var P = G.multiply(a);
    return JSON.stringify({"x": P.x, "y": P.y, "z": P.z});
}

function generate_secret_key(my_private_key, friends_public_key) {
    var c = getSECCurveByName("secp256r1").getCurve();
    

    var public_dict = JSON.parse(friends_public_key);
    var x = new ECFieldElementFp(public_dict.x.q, public_dict.x.x);
    x.q.__proto__ = BigInteger.prototype;
    x.x.__proto__ = BigInteger.prototype;
    var y = new ECFieldElementFp(public_dict.y.q, public_dict.y.x);
    y.q.__proto__ = BigInteger.prototype;
    y.x.__proto__ = BigInteger.prototype;
    var z = public_dict.z;
    z.__proto__ = BigInteger.prototype;
    var P = new ECPointFp(c, x, y, z);
    
    var a = new BigInteger(my_private_key);
    var S = P.multiply(a);
    return S.getX().toBigInteger().toString() + S.getY().toBigInteger().toString();
}