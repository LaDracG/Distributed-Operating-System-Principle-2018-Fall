defmodule Alg do
  def bin2hex(bin) do
    Base.encode16(bin)
  end

  def hex2bin(hex) do
    Base.decode16!(hex)
  end

  def hashStruct(alg, object, num_rounds) do
    if num_rounds > 0 do
      vlist = Map.values(Map.from_struct(object))
      res = :crypto.hash(alg, vlist) |> Base.encode16
      hashString(alg, res, num_rounds-1)
    else
      IO.puts "The number of hash rounds cannot be zero."
      nil
    end
  end

  def hashString(alg, string, num_rounds) do
    if num_rounds > 0 do
      res = :crypto.hash(alg, string) |> Base.encode16
      hashString(alg, res, num_rounds-1)
    else
      string
    end
  end

  def hashTransaction(transaction) do
    hashStruct(:sha256, transaction, 2)
  end

  def generateMerkleTree(transactions) do

  end

  def generateKeyPair() do
    {public_key, private_key} = :crypto.generate_key(:ecdh, :secp256k1)
    {Base.encode16(public_key), Base.encode16(private_key)}
  end

  def generateSignature(private_key, message) do
    private_key = hex2bin(private_key)
    :crypto.sign(:ecdsa, :sha256, message, [private_key, :secp256k1]) |> Base.encode16
  end

  def verifySignature(signature, public_key, message) do
    public_key = hex2bin(public_key)
    signature = hex2bin(signature)
    :crypto.verify(:ecdsa, :sha256, message, signature, [public_key, :secp256k1])
  end

  def signTransaction(sender_private_key, prev_trans_hash, receiver_public_key) do
    hash = hashString(:sha256, prev_trans_hash<>receiver_public_key, 2)
    generateSignature(sender_private_key, hash)
  end

  def verifyTransaction(signature, sender_public_key, prev_trans_hash, receiver_public_key) do
    hash = hashString(:sha256, prev_trans_hash<>receiver_public_key, 2)
    verifySignature(signature, sender_public_key, hash)
  end

end
