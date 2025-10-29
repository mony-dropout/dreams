import { ethers } from "ethers";
import { EAS, SchemaEncoder } from "@ethereum-attestation-service/eas-sdk";

const ZERO_BYTES32 = ("0x" + "00".repeat(32)) as `0x${string}`;

function txExplorerBaseForChain(chainId: bigint): string | null {
  // Minimal mapping; extend as needed.
  if (chainId === 84532n) return "https://sepolia.basescan.org"; // Base Sepolia
  if (chainId === 11155111n) return "https://sepolia.etherscan.io"; // Ethereum Sepolia
  return null;
}

export async function attestGoal(params: {
  goalId: string;
  result: "PASS" | "FAIL";
  recipientAddress?: string; // optional; defaults to signer
}): Promise<{ uid: string; txHash?: string; txUrl?: string }> {
  const rpc = process.env.RPC_URL_BASE_SEPOLIA;
  const pk = process.env.PLATFORM_PRIVATE_KEY;
  const contract = process.env.EAS_CONTRACT_ADDRESS;
  const schemaId = process.env.EAS_SCHEMA_ID;

  if (!rpc || !pk || !contract || !schemaId) {
    // Fallback: no on-chain write
    return { uid: "0xDEMO_ATTESTATION_UID_NO_ENV_SET" };
  }

  const provider = new ethers.JsonRpcProvider(rpc);
  const wallet = new ethers.Wallet(pk, provider);

  const eas = new EAS(contract);
  await eas.connect(wallet);

  // Define your schema locally to match EAS schema you created
  // Example schema: "string goalId,string result"
  const schemaEncoder = new SchemaEncoder("string goalId,string result");
  const encoded = schemaEncoder.encodeData([
    { name: "goalId", value: params.goalId, type: "string" },
    { name: "result", value: params.result, type: "string" },
  ]);

  const recipient = ((): `0x${string}` => {
    const cand = params.recipientAddress || wallet.address;
    return /^0x[0-9a-fA-F]{40}$/.test(cand) ? (cand as `0x${string}`) : (wallet.address as `0x${string}`);
  })();

  const tx = await eas.attest({
    schema: schemaId,
    data: {
      recipient,
      expirationTime: 0n,
      revocable: false,
      refUID: ZERO_BYTES32,
      data: encoded,
      value: 0n,
    },
  });

  const uid = await tx.wait();
  let txHash: string | undefined = (tx as any)?.hash;
  try {
    // In case hash not present on tx object, we can pull from receipt
    const receipt = await provider.getTransactionReceipt(txHash as `0x${string}`);
    if (receipt?.transactionHash) txHash = receipt.transactionHash;
  } catch {}

  let txUrl: string | undefined;
  try {
    const net = await provider.getNetwork();
    const base = txExplorerBaseForChain(net.chainId);
    if (base && txHash) txUrl = `${base}/tx/${txHash}`;
  } catch {}

  return { uid, txHash, txUrl };
}
