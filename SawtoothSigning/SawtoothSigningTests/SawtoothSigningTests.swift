//
//  SawtoothSigningTests.swift
//  SawtoothSigningTests
//
//  Copyright 2018 Bitwise IO, Inc.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
import XCTest
import secp256k1
@testable import SawtoothSigning

class SawtoothSigningTests: XCTestCase {

    override func setUp() {}

    override func tearDown() {}

    /// Test that the correct public key is generated using the Context.getPublicKey() method.
    func testGetPublicKey() {
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
        let context = Secp256k1Context()

        let privateKey = Secp256k1PrivateKey.fromHex(
            hexPrivKey: "80378f103c7f1ea5856d50f2dcdf38b97da5986e9b32297be2de3c8444c38c08")
        var ecKey = secp256k1_pubkey()
        _ = secp256k1_ec_pubkey_create(ctx!, &ecKey, privateKey.getBytes())

        var pubKeyBytes = [UInt8](repeating: 0, count: 33)
        var outputLen = 33
        _ = secp256k1_ec_pubkey_serialize(
            ctx!, &pubKeyBytes, &outputLen, &ecKey, UInt32(SECP256K1_EC_COMPRESSED))

        let actualPublicKey = context.getPublicKey(privateKey: privateKey)

        let expectedPublicKey = Secp256k1PublicKey(pubKey: pubKeyBytes)

        XCTAssertEqual(actualPublicKey.hex(), expectedPublicKey.hex())
        secp256k1_context_destroy(ctx)
    }

    /// Test that the correct signature is generated by signing a message
    func testSign() {
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
        let context = Secp256k1Context()

        let privateKey = Secp256k1PrivateKey.fromHex(
            hexPrivKey: "80378f103c7f1ea5856d50f2dcdf38b97da5986e9b32297be2de3c8444c38c08")
        let signer = Signer(context: context, privateKey: privateKey)
        let message: [UInt8] = Array("Hello, Alice, this is Bob.".utf8)

        let actualSignature = signer.sign(data: message)

        // This Signature was created with the Python sawtooth_signing library.
        let expectedSignature = """
        b7eec6dc1e4c3b64f0d5bae3f0e6be3978120c69ea1c8b5987921a869f36cb26\
        2a4200527f9a06585a4d461281e008b929f7c4ec24880d2baf2a774cfc61969a
        """

        XCTAssertEqual(actualSignature, expectedSignature)
        secp256k1_context_destroy(ctx)
    }

    /// Test that a context can verify when a signature is valid."
    func testVerify() {
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
        let context = Secp256k1Context()

        let privateKey = Secp256k1PrivateKey.fromHex(
            hexPrivKey: "80378f103c7f1ea5856d50f2dcdf38b97da5986e9b32297be2de3c8444c38c08")
        let signer = Signer(context: context, privateKey: privateKey)
        let message: [UInt8] = Array("Hello, Alice, this is Bob.".utf8)

        let actualSignature = signer.sign(data: message)
        let result = context.verify(signature: actualSignature, data: message, publicKey: signer.getPublicKey())

        XCTAssertTrue(result)
        secp256k1_context_destroy(ctx)
    }

    /// Test that a context can verify when a signature is invalid"
    func testVerifyError() {
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
        let context = Secp256k1Context()
        let privateKey = Secp256k1PrivateKey.fromHex(
            hexPrivKey: "80378f103c7f1ea5856d50f2dcdf38b97da5986e9b32297be2de3c8444c38c08")
        let signer = Signer(context: context, privateKey: privateKey)
        let message: [UInt8] = Array("Hello, Alice, this is Bob.".utf8)

         // This signature doesn't match for message
        let signature =  """
            d589c7b1fa5f8a4c5a389de80ae9582c2f7f2a5\
            e21bab5450b670214e5b1c1235e9eb8102fd0ca690a8b42e2c406a682bd57f6daf6e142e5fa4b2c26ef40a490
        """
        let result = context.verify(signature: signature, data: message, publicKey: signer.getPublicKey())
        XCTAssertFalse(result)
        secp256k1_context_destroy(ctx)
    }
}
