// /// Imports
// import 'package:solana_web3/solana_web3.dart' as web3;
// import 'package:solana_web3/programs/system.dart';

// /// Transfer tokens from one wallet to another.
// void main(final List<String> _arguments) async {

//     // Create a connection to the devnet cluster.
//     final cluster = web3.Cluster.devnet;
//     final connection = web3.Connection(cluster);

//     print('Creating accounts...\n');

//     // Create a new wallet to transfer tokens from.
//     final wallet1 = web3.Keypair.generateSync();
//     final address1 = wallet1.pubkey;

//     // Create a new wallet to transfer tokens to.
//     final wallet2 = web3.Keypair.generateSync();
//     final address2 = wallet2.pubkey;

//     // Fund the sending wallet.
//     await connection.requestAndConfirmAirdrop(
//       wallet1.pubkey,
//       solToLamports(2).toInt(),
//     );

//     // Check the account balances before making the transfer.
//     final balance = await connection.getBalance(wallet1.pubkey);
//     print('Account $address1 has an initial balance of $balance lamports.');
//     print('Account $address2 has an initial balance of 0 lamports.\n');

//     // Fetch the latest blockhash.
//     final BlockhashWithExpiryBlockHeight blockhash = await connection.getLatestBlockhash();

//     // Create a System Program instruction to transfer 0.5 SOL from [address1] to [address2].
//     final transaction = web3.Transaction.v0(
//       payer: wallet1.pubkey,
//       recentBlockhash: blockhash.blockhash,
//       instructions: [
//         SystemProgram.transfer(
//           fromPubkey: address1,
//           toPubkey: address2,
//           lamports: web3.solToLamports(0.5),
//         ),
//       ]
//     );

//     // Sign the transaction.
//     transaction.sign([wallet1]);

//     // Send the transaction to the cluster and wait for it to be confirmed.
//     print('Send and confirm transaction...\n');
//     await connection.sendAndConfirmTransaction(
//       transaction,
//     );

//     // Check the updated account balances.
//     final wallet1balance = await connection.getBalance(wallet1.pubkey);
//     final wallet2balance = await connection.getBalance(wallet2.pubkey);
//     print('Account $address1 has an updated balance of $wallet1balance lamports.');
//     print('Account $address2 has an updated balance of $wallet2balance lamports.');
// }

import 'dart:convert';

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:solana/base58.dart';
import 'package:solana/encoder.dart';
import 'package:solana/encoder.dart' as msg;
import 'package:solana/solana.dart';
import 'package:solana/solana.dart' as solana;
import 'package:solana_mobile_client/solana_mobile_client.dart';
import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';
import 'package:solana_web3/buffer.dart' as web31;
import 'package:solana_web3/solana_web3.dart';

//import 'package:solana_web3/programs/system.dart' as web32;


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<void> _future;

  static final Cluster cluster = Cluster.devnet;
  String walletAddress = '';
  String balance = 'N/A';
  bool isConnected = false;
  final client = MobileWalletAdapterClient(1);
  AuthorizationResult? _authResult;
  String _balance = "Not Connected";

  // final _solanaClient = SolanaClient(
  //   rpcUrl: Uri.parse('https://api.devnet.solana.com'), // or devnet/mainnet
  //   websocketUrl: Uri.parse('wss://api.devnet.solana.com'),
  // );
  late final SolanaClient _solanaClient;

  final SolanaWalletAdapter adapter = SolanaWalletAdapter(
    AppIdentity(
      name: 'My Solana App',
      uri: Uri.parse('https://example.com'),
      icon: Uri.parse('favicon.png'),
    ),
    cluster: cluster,
  );

  String? _status;

  @override
  void initState() {
    super.initState();
    _future = SolanaWalletAdapter.initialize();
    _solanaClient = SolanaClient(
      rpcUrl: Uri.parse('https://api.devnet.solana.com'),
      websocketUrl: Uri.parse('wss://api.devnet.solana.com'),
    );
  }

  String base64ToBase58(String base64Key) {
    final bytes = base64.decode(base64Key);
    final base58Key = base58.encode(bytes);
    final pubkey = Pubkey.fromBase58(base58Key);
    return pubkey.toBase58();
  }

  Future<bool> _doAuthorize(MobileWalletAdapterClient client) async {
    final result = await client.authorize(
      identityUri: Uri.parse('https://solana.com'),
      iconUri: Uri.parse('favicon.ico'),
      identityName: 'Solana',
      cluster: 'devnet',
    );

    _authResult = result;
    print(_authResult);
    print(result);
    

    return result != null;
  }


Future<void> authorizeWallet(BuildContext context) async {
  try {
    // Create a local session
    final session = await LocalAssociationScenario.create();

    // Start activity to trigger wallet app (Phantom, Solflare, etc.)
    session.startActivityForResult(null).ignore();

    // Wait for wallet to connect
    final client = await session.start();

    // Try to authorize
    final authResult = await client.authorize(
      identityUri: Uri.parse('https://example.com'),
      iconUri: Uri.parse('favicon.png'),
      identityName: "My Solana App",
      cluster: "devnet", // Change to mainnet-beta if needed
    );

    if (authResult == null) {
      _showError(context, "Authorization cancelled or failed. Please approve the request in your wallet.");
    } else {
      debugPrint("✅ Authorization successful!");
      debugPrint("Public Key: ${authResult.publicKey}");
      // You can now store authResult.publicKey and proceed
    }

    await session.close();
  } catch (e, st) {
    debugPrint("❌ Authorization error: $e");
    debugPrintStack(stackTrace: st);
    _showError(context, "Something went wrong while authorizing the wallet.");
  }
}

// Simple error popup
void _showError(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Wallet Authorization"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
  Future<bool> _doReauthorize(MobileWalletAdapterClient client) async {
    final authToken = _authResult?.authToken;
    if (authToken == null) return false;

    final result = await client.reauthorize(
      identityUri: Uri.parse('https://solana.com'),
      iconUri: Uri.parse('favicon.ico'),
      identityName: 'Solana',
      authToken: authToken,
    );

    _authResult = result;

    return result != null;
  }

  /// Connect wallet
  Future<void> _connect() async {
    try {
      if (!adapter.isAuthorized) {
        await adapter.authorize(
          walletUriBase:
              adapter.store.apps[0].walletUriBase, // Use first wallet
        );
        
      }
      setState(() {
        _status =
            "Connected: $walletAddress."; //${adapter.publicKey?.toBase58()}";
        var x = adapter.connectedAccount!.address;
        print('Connected to wallet: $walletAddress');
        walletAddress = base64ToBase58(x);
        print(x);
        isConnected = true;
        fetchWalletBalance();
      });
      adapter.connectedAccount!.label;
     // adapter.clear();
    } catch (e) {
      setState(() {
        _status = "Connection failed: $e";
      });
    }
  }




  /// Disconnect wallet
  Future<void> _disconnect() async {
    await adapter.deauthorize();
    setState(() {
      _status = "Disconnected";
      walletAddress = '';
      balance = 'N/A';
      isConnected = false;
    });
  }

  // Function to fetch the wallet balance
  Future<void> fetchWalletBalance() async {
    if (!isConnected) return;

    setState(() {
      balance = 'Loading...';
    });

    try {
      print('Fetching balance for wallet: $walletAddress');
      // Create a connection to Solana (use mainnet-beta for real SOL)
      final connection = Connection(cluster);

      // Get the public key from connected wallet
      final publicKey = Pubkey.fromBase58(walletAddress);

      // Fetch the balance
      final balanceResponse = await connection.getBalance(publicKey);
      final balanceInSol =
          balanceResponse / 1000000000; // Convert lamports to SOL

      setState(() {
        balance = '${balanceInSol.toStringAsFixed(4)} SOL';
      });
    } catch (error) {
      setState(() {
        balance = 'Error: $error';
      });
    }
  }



  Future<void> sendLamports() async {
    if (!isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please connect wallet')));
      return;
    }

    try {
      // Validate inputs
    //  final walletAddress = walletController.text.trim();
      if (!RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$').hasMatch(walletAddress)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid wallet address')));
        return;
      }
      final amount = double.tryParse(0.01.toString());
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid amount')));
        return;
      }

      final recipient = Ed25519HDPublicKey.fromBase58('671BcDWFBURi8fJuHURDKHoZVkouQ5D1EzHvrhPjoWTD');
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

      final signer = Ed25519HDPublicKey.fromBase58(adapter.connectedAccount!.address);
      final blockhash =
          (await _solanaClient.rpcClient.getLatestBlockhash()).value.blockhash;
      final instruction = SystemInstruction.transfer(
        fundingAccount: signer,
        recipientAccount: recipient,
        lamports: (amount * solana.lamportsPerSol).toInt(),
      );
      final message = msg.Message(
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

      final signature = await _solanaClient.rpcClient.sendTransaction(
        base64.encode(signResult.signedPayloads[0]),
        preflightCommitment: solana.Commitment.confirmed,
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
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Solana Wallet Demo'),
            backgroundColor: Colors.deepPurple,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Status: $isConnected',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Text(
                  balance == 'N/A' ? 'Balance: N/A' : 'Balance: $balance',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Text(
                  _status ?? "Not connected",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: const Text("Connect Wallet"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _disconnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: const Text("Disconnect"),
                ),
                //signAndSendTransactions
                const SizedBox(height: 10),
                // ElevatedButton(
                //   onPressed: () => signAndSendTransactions(2),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.blue,
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 30,
                //       vertical: 15,
                //     ),
                //   ),
                //   child: const Text("Sign & Send 2 Transactions"),
                // ),
                // //_doAuthorize
                // const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () =>  sendLamports(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: const Text("Sign & Send 2 Transactions"),
                ),
                //_doAuthorize
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => authorizeWallet(context), // _doAuthorize(client),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: const Text("Authorize"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
