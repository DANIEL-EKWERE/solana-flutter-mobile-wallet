import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';
import 'package:solana_web3/programs.dart';
import 'package:solana_web3/solana_web3.dart';

/// Send SOL Screen
class SendSOLScreen extends StatefulWidget {
  const SendSOLScreen({super.key});

  @override
  State<SendSOLScreen> createState() => _SendSOLScreenState();
}

class _SendSOLScreenState extends State<SendSOLScreen> {
  /// Initialization future
  late final Future<void> _future;

  /// Cluster configuration
  static final Cluster cluster = Cluster.devnet;

  /// Status message
  String? _status;
  
  /// Loading state
  bool _isLoading = false;

  /// Form controllers
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Wallet adapter instance
  final SolanaWalletAdapter adapter = SolanaWalletAdapter(
    AppIdentity(
      uri: Uri.https('merigo.com'),   // YOUR_APP_DOMAIN.
      icon: Uri.parse('favicon.png'), // YOUR_ICON_PATH relative to `uri`
      name: 'Send SOL App',
    ),
    cluster: cluster,
    hostAuthority: null,
  );

  @override
  void initState() {
    super.initState();
    _future = SolanaWalletAdapter.initialize();
    _status = 'Ready to send SOL';
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Connect to wallet
  Future<void> _connectWallet() async {
    if (!adapter.isAuthorized) {
      setState(() {
        _isLoading = true;
        _status = 'Connecting to wallet...';
      });
      
      try {
        await adapter.authorize(walletUriBase: adapter.store.apps.isNotEmpty 
            ? adapter.store.apps.first.walletUriBase 
            : null);
        
        setState(() {
          _status = 'Wallet connected successfully!';
          _isLoading = false;
        });
      } catch (error) {
        setState(() {
          _status = 'Connection failed: $error';
          _isLoading = false;
        });
      }
    }
  }

  /// Disconnect from wallet
  Future<void> _disconnectWallet() async {
    if (adapter.isAuthorized) {
      setState(() {
        _isLoading = true;
        _status = 'Disconnecting...';
      });
      
      try {
        await adapter.deauthorize();
        setState(() {
          _status = 'Wallet disconnected';
          _isLoading = false;
        });
      } catch (error) {
        setState(() {
          _status = 'Disconnect failed: $error';
          _isLoading = false;
        });
      }
    }
  }

  /// Request airdrop for devnet
  Future<void> _requestAirdrop() async {
    if (cluster == Cluster.mainnet) {
      setState(() => _status = 'Airdrop not available on mainnet');
      return;
    }

    final Pubkey? wallet = Pubkey.tryFromBase64(adapter.connectedAccount?.address);
    if (wallet == null) {
      setState(() => _status = 'Wallet not connected');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Requesting 2 SOL airdrop...';
    });

    try {
      final Connection connection = Connection(cluster);
      await connection.requestAndConfirmAirdrop(wallet, solToLamports(2).toInt());
      
      setState(() {
        _status = '✅ Airdrop successful! 2 SOL added to your wallet';
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _status = '❌ Airdrop failed: $error';
        _isLoading = false;
      });
    }
  }

  /// Get wallet balance
  Future<void> _getBalance() async {
    final Pubkey? wallet = Pubkey.tryFromBase64(adapter.connectedAccount?.address);
    if (wallet == null) return;

    setState(() {
      _isLoading = true;
      _status = 'Fetching balance...';
    });

    try {
      final Connection connection = Connection(cluster);
      final int balance = await connection.getBalance(wallet);
      final double balanceSOL = balance / 1000000000;
      
      setState(() {
        _status = 'Current balance: ${balanceSOL.toStringAsFixed(6)} SOL';
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _status = 'Failed to fetch balance: $error';
        _isLoading = false;
      });
    }
  }

  /// Send SOL to specified address
//   Future<void> _sendSOL() async {
//     if (!_formKey.currentState!.validate()) return;

//     final String recipientAddress = _recipientController.text.trim();
//     final double amount = double.parse(_amountController.text.trim());

//     setState(() {
//       _isLoading = true;
//       _status = 'Preparing to send $amount SOL...';
//     });

//     try {
//       final Connection connection = Connection(cluster);
      
//       // Validate connected wallet
//       final Pubkey? senderWallet = Pubkey.tryFromBase64(adapter.connectedAccount?.address);
//       if (senderWallet == null) {
//         throw 'Wallet not connected';
//       }

//       // Validate recipient address
//       final Pubkey? recipientWallet = Pubkey.tryFromBase58(recipientAddress);
//       if (recipientWallet == null) {
//         throw 'Invalid recipient address';
//       }

//       // Check balance
//       setState(() => _status = 'Checking balance...');
//       final int balance = await connection.getBalance(senderWallet);
//       final BigInt lamportsToSend = solToLamports(amount);
//       final int requiredBalance = (5000 + lamportsToSend.toInt()); // Transaction fee + amount
      
//       if (balance < requiredBalance) {
//         if (cluster != Cluster.mainnet) {
//           setState(() => _status = 'Insufficient balance, requesting airdrop...');
//           await connection.requestAndConfirmAirdrop(senderWallet, solToLamports(2).toInt());
//         } else {
//           throw 'Insufficient balance. Required: ${requiredBalance / 1000000000} SOL, Available: ${balance / 1000000000} SOL';
//         }
//       }

//       // Create transaction
//       setState(() => _status = 'Creating transaction...');
//       final latestBlockhash = await connection.getLatestBlockhash();
//       print('latest block hash: ${latestBlockhash.blockhash}');
//       final Transaction transaction = Transaction.v0(
//         payer: senderWallet,
//         recentBlockhash: latestBlockhash.blockhash,
//         instructions: [
//           SystemProgram.transfer(
//             fromPubkey: senderWallet,
//             toPubkey: recipientWallet,
//             lamports: lamportsToSend,
//           )
//         ],
//       );
// print(transaction.message);
// print(transaction.signatures);

//       // Sign and send transaction
//       setState(() => _status = 'Signing transaction...');

//       final SignAndSendTransactionsResult result = await adapter.signAndSendTransactions([
//         adapter.encodeTransaction(transaction)
//       ]);
//       print(result);

//       // Wait for confirmation
//       setState(() => _status = 'Confirming transaction...');
//       await connection.confirmTransaction(base58To64Decode(result.signatures.first!));

//       // Success
//       setState(() {
//         _status = '✅ Success!\n\n'
//             'Sent $amount SOL to:\n${recipientAddress.substring(0, 20)}...\n\n'
//             'Transaction Signature:\n${result.signatures.first}';
//         _isLoading = false;
//       });

//       // Clear form
//       _recipientController.clear();
//       _amountController.clear();

//     } catch (error) {
//       setState(() {
//         _status = '❌ Transfer failed: $error';
//         _isLoading = false;
//       });
//     }
//   }


Future _sendSOL() async {
  if (!_formKey.currentState!.validate()) return;
  
  final String recipientAddress = _recipientController.text.trim();
  final double amount = double.parse(_amountController.text.trim());
  
  setState(() {
    _isLoading = true;
    _status = 'Preparing to send $amount SOL...';
  });

  try {
    final Connection connection = Connection(cluster);
    
    // Validate connected wallet
    final Pubkey? senderWallet = Pubkey.tryFromBase64(adapter.connectedAccount?.address);
    if (senderWallet == null) throw 'Wallet not connected';
    
    // Validate recipient
    final Pubkey? recipientWallet = Pubkey.tryFromBase58(recipientAddress);
    if (recipientWallet == null) throw 'Invalid recipient address';
    
    // Check balance
    setState(() => _status = 'Checking balance...');
    final int balance = await connection.getBalance(senderWallet);
    final BigInt lamportsToSend = solToLamports(amount);
    final int requiredBalance = lamportsToSend.toInt() + 5000;
    
    if (balance < requiredBalance) {
      if (cluster != Cluster.mainnet) {
        setState(() => _status = 'Airdropping SOL...');
        await connection.requestAndConfirmAirdrop(senderWallet, solToLamports(2).toInt());
      } else {
        throw 'Insufficient balance. Need ${(requiredBalance / 1e9)} SOL';
      }
    }
    
    // Build transaction
    setState(() => _status = 'Creating transaction...');
    final latestBlockhash = await connection.getLatestBlockhash();
    
    final tx = Transaction.v0(
      payer: senderWallet,
      recentBlockhash: latestBlockhash.blockhash,
      instructions: [
        SystemProgram.transfer(
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
    
    // The signed transaction from Phantom should be sent directly
    final signedTx = Transaction.deserialize(signedTxBytes);
    final sig = await connection.sendTransaction(signedTx);
    
    print('TX Signature: $sig');
    
    // Confirm transaction
    setState(() => _status = 'Confirming transaction...');
    await connection.confirmTransaction(sig);
    
    setState(() {
      _status = '✅ Sent $amount SOL!\nSignature: $sig';
      _isLoading = false;
    });
    
    _recipientController.clear();
    _amountController.clear();
    
  } catch (e) {
    print('Error details: $e');
    setState(() {
      _status = '❌ Transfer failed: $e';
      _isLoading = false;
    });
  }
}

  /// Quick send preset amounts
  void _quickSend(double amount) {
    _amountController.text = amount.toString();
  }

  /// Paste from clipboard
  Future<void> _pasteFromClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null) {
        _recipientController.text = data!.text!;
        setState(() {});
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to paste: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send SOL'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                _buildStatusCard(),
                
                const SizedBox(height: 20),
                
                // Wallet Connection Section
                _buildWalletSection(),
                
                const SizedBox(height: 20),
                
                // Send SOL Form (only show if connected)
                if (adapter.isAuthorized) ...[
                  _buildSendForm(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard() {
    Color cardColor;
    Color textColor;
    IconData icon;

    if (_status?.contains('Success') == true || _status?.contains('✅') == true) {
      cardColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle;
    } else if (_status?.contains('failed') == true || _status?.contains('❌') == true) {
      cardColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = Icons.error;
    } else if (_isLoading) {
      cardColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.hourglass_empty;
    } else {
      cardColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      icon = Icons.info;
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (_isLoading) 
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else 
              Icon(icon, color: textColor),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Text(
                _status ?? 'Ready',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Wallet Connection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (adapter.isAuthorized) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Connected',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Address: ${adapter.connectedAccount?.toBase58().substring(0, 20) ?? 'Unknown'}...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getBalance,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check Balance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  if (cluster != Cluster.mainnet)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _requestAirdrop,
                        icon: const Icon(Icons.water_drop),
                        label: const Text('Get Devnet SOL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _disconnectWallet,
                icon: const Icon(Icons.logout),
                label: const Text('Disconnect Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _connectWallet,
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Connect Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSendForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Send SOL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Recipient Address Field
              TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  labelText: 'Recipient Address',
                  hintText: 'Enter Solana wallet address',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: _pasteFromClipboard,
                    tooltip: 'Paste from clipboard',
                  ),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a recipient address';
                  }
                  
                  if (Pubkey.tryFromBase58(value.trim()) == null) {
                    return 'Invalid Solana address';
                  }
                  
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (SOL)',
                  hintText: '0.001',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  
                  if (amount > 1000) {
                    return 'Amount seems too large';
                  }
                  
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Send Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendSOL,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Sending...' : 'Send SOL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quick Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildQuickAmountChip(0.001),
                _buildQuickAmountChip(0.01),
                _buildQuickAmountChip(0.1),
                _buildQuickAmountChip(1.0),
                _buildQuickAmountChip(5.0),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Network: ${cluster.name?.toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (cluster != Cluster.mainnet)
                    Text(
                      'You\'re on ${cluster.name}. Get free SOL using "Get Devnet SOL" button.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    )
                  else
                    Text(
                      'You\'re on mainnet. This uses real SOL!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(double amount) {
    return ActionChip(
      label: Text('${amount.toString()} SOL'),
      onPressed: () => _quickSend(amount),
      backgroundColor: Colors.purple.shade50,
      labelStyle: TextStyle(color: Colors.purple.shade700),
      side: BorderSide(color: Colors.purple.shade200),
    );
  }
}