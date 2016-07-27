function encodedHMAC = HMACencode(str,key)

%encodedHMAC = urlEncode(doHMAC_SHA1(str, key));
encodedHMAC = doHMAC_SHA1(str, key);

end

function signStr = doHMAC_SHA1(str, key)
import java.net.*;
import javax.crypto.*;
import javax.crypto.spec.*;
import org.apache.commons.codec.binary.*
algorithm = 'HmacSHA1';
keyStr = java.lang.String(key);
key = SecretKeySpec(keyStr.getBytes(), algorithm);
mac = Mac.getInstance(algorithm);
mac.init(key);
toSignStr = java.lang.String(str);
bytes = toSignStr.getBytes();
signStr = java.lang.String(Base64.encodeBase64(mac.doFinal(bytes)));
signStr = (signStr.toCharArray())';
signStr = strrep(signStr, '\n', '');
signStr = strrep(signStr, '\r', '');
end

function encodedStr = urlEncode(str)
import java.net.*;
encoded = URLEncoder.encode(str, 'UTF-8');
encodedStr = (encoded.toCharArray())';
encodedStr = strrep(encodedStr, '+', '%20');
end