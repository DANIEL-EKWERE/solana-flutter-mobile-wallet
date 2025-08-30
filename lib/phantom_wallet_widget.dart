import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:solana/base58.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:solana_mobile_client/solana_mobile_client.dart';

class Day2Screen extends StatefulWidget {
  const Day2Screen({super.key});
  @override
  State<Day2Screen> createState() => _Day2ScreenState();
}

class _Day2ScreenState extends State<Day2Screen> {
  final client = SolanaClient(
    rpcUrl: Uri.parse("https://api.mainnet-beta.solana.com"),
    websocketUrl: Uri.parse("wss://api.mainnet-beta.solana.com"),
  );
  final walletController = TextEditingController();
  final amountController = TextEditingController();
  AuthorizationResult? result;
  bool isWalletConnected = false;

  Future<void> connectWallet() async {
    try {
      final scenario = await LocalAssociationScenario.create();
      scenario.startActivityForResult(null).ignore();
      final mwaClient = await scenario.start();
      result = await mwaClient.authorize(
        identityUri: Uri.parse("https://placeholder.com/"),
        iconUri: Uri.parse("favicon.ico"),
        identityName: "Workshop",
        cluster: 'mainnet-beta',
      );
      if (result?.publicKey != null) {
        setState(() => isWalletConnected = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Wallet connected')));
      } else {
        throw Exception('No public key returned');
      }
      await scenario.close();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection error: $e')));
    }
  }

  Future<bool> _doReauthorize(MobileWalletAdapterClient mwaClient) async {
    try {
      final reauthorizeResult = await mwaClient.reauthorize(
        identityUri: Uri.parse("https://placeholder.com/"),
        iconUri: Uri.parse("favicon.ico"),
        identityName: "Workshop",
        authToken: result!.authToken,
      );
      return reauthorizeResult?.publicKey != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> sendLamports() async {
    if (!isWalletConnected || result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please connect wallet')));
      return;
    }

    try {
      // Validate inputs
      final walletAddress = walletController.text.trim();
      if (!RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$').hasMatch(walletAddress)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid wallet address')));
        return;
      }
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid amount')));
        return;
      }

      final recipient = Ed25519HDPublicKey.fromBase58(walletAddress);
      final scenario = await LocalAssociationScenario.create();
      scenario.startActivityForResult(null).ignore();
      final mwaClient = await scenario.start();

      if (!await _doReauthorize(mwaClient)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reauthorization failed')));
        await scenario.close();
        return;
      }

      final signer = Ed25519HDPublicKey(result!.publicKey);
      final blockhash =
          (await client.rpcClient.getLatestBlockhash()).value.blockhash;
      final instruction = SystemInstruction.transfer(
        fundingAccount: signer,
        recipientAccount: recipient,
        lamports: (amount * lamportsPerSol).toInt(),
      );
      final message = Message(
        instructions: [instruction],
      ).compile(recentBlockhash: blockhash, feePayer: signer);
      final signedTx = SignedTx(
        compiledMessage: message,
        signatures: [Signature(List.filled(64, 0), publicKey: signer)],
      );
      final serializedTx = Uint8List.fromList(signedTx.toByteArray().toList());
      final signResult = await mwaClient.signTransactions(
        transactions: [serializedTx],
      );

      if (signResult.signedPayloads.isEmpty) {
        throw Exception('No signed payloads returned');
      }

      final signature = await client.rpcClient.sendTransaction(
        base64.encode(signResult.signedPayloads[0]),
        preflightCommitment: Commitment.confirmed,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sent: $signature')));
      await scenario.close();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: isWalletConnected ? null : connectWallet,
            child: Text(isWalletConnected ? 'Connected' : 'Connect Wallet'),
          ),
          TextField(
            controller: walletController,
            enabled: isWalletConnected,
            decoration: const InputDecoration(hintText: 'Recipient Address'),
          ),
          TextField(
            controller: amountController,
            enabled: isWalletConnected,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Amount (SOL)'),
          ),
          ElevatedButton(
            onPressed: isWalletConnected ? sendLamports : null,
            child: const Text('Send SOL'),
          ),
          if (isWalletConnected && result != null)
            Text('Connected: ${base58encode(result!.publicKey)}'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    walletController.dispose();
    amountController.dispose();
    super.dispose();
  }
}