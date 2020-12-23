const { web3 } = require('@openzeppelin/test-environment');

module.exports = {
    stringToBytes: function(str, pad = false) {
        let bytes = web3.utils.utf8ToHex(str);
        if (pad) {
            bytes = web3.utils.padRight(bytes, 64, '0');
        }

        return bytes;
    },
};