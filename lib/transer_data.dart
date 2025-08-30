
import 'package:solana_web3/solana_web3.dart';

class TransferData {
  const TransferData({
    required this.transaction,
    required this.receiver,
    required this.lamports,
  });
  final Transaction transaction;
  final Keypair receiver;
  final BigInt lamports;
}
