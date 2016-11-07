function PNAES() as Object
    instance = {
        private: { initializationVector: "0123456789012345" }
    }
    
    instance.private.SHA256HexFromKey = function(key as String) as Dynamic
        encodedKey = invalid
        if key <> invalid AND key.len() > 0 then
            keyData = CreateObject("roByteArray")
            keyData.fromAsciiString(key)
            digest = CreateObject("roEVPDigest")
            digest.setup("sha256")
            encodedKey = digest.process(keyData)
            if encodedKey <> invalid then encodedKey = UCase(encodedKey.left(32))
        end if
        
        return encodedKey
    end function
    
    instance.encrypt = function(data as Object, key as String) as Dynamic
        encryptedData = invalid
        encryptionKey = m.private.SHA256HexFromKey(key)
        if encryptionKey <> invalid
            
        end if
        
        return encryptedData
    end function
    
    return instance
end function