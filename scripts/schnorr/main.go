package main

import (
	"encoding/hex"
	"log"
	"os"

	"github.com/btcsuite/btcd/btcec/v2"
	"github.com/btcsuite/btcd/btcec/v2/schnorr"
	"github.com/joho/godotenv"
	"github.com/wealdtech/go-merkletree/keccak256"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	schnorrKeyHex := os.Getenv("SCHNORR_KEY")
	schnorrKeyBytes, err := hex.DecodeString(schnorrKeyHex)
	if err != nil {
		log.Fatal("Error decoding schnorr key")
	}

	privateKey, publicKey := btcec.PrivKeyFromBytes(schnorrKeyBytes)
	log.Printf("Public key: 0x%x\n", publicKey.X().Bytes())

	message := []byte("Hello, world!")
	hash := keccak256.New().Hash(message)

	log.Printf("Message: 0x%x\n", hash)

	signature, err := schnorr.Sign(privateKey, hash, []schnorr.SignOption{}...)
	if err != nil {
		log.Fatal("Error signing message", err)
	}

	log.Printf("Signature: 0x%x\n", signature.Serialize())
	log.Printf("Signature: 0x%x\n", signature.Serialize()[:32])
	log.Printf("Signature: 0x%x\n", signature.Serialize()[32:])
}
