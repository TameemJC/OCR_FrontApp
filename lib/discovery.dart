import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';

class ServerDiscoveryService {

  static Future<String?> discoverServer() async {

    final directUrl = await _tryDirectConnections();
    if (directUrl != null) return directUrl;

    final commonUrl = await _tryCommonAddresses();
    if (commonUrl != null) return commonUrl;

    final broadcastUrl = await _discoverViaBroadcast();
    if (broadcastUrl != null) return broadcastUrl;

    final scannedUrl = await _scanLocalNetwork();
    if (scannedUrl != null) return scannedUrl;

    return null;
  }

  static Future<String?> _tryDirectConnections() async {
    final directIps = <String>[];

    directIps.addAll([
      'http://10.1.1.36:5000',

      'http://172.20.10.1:5000',
      'http://172.20.10.2:5000',
      'http://172.20.10.3:5000',
      'http://172.20.10.4:5000',
      'http://172.20.10.5:5000',

      'http://192.168.43.1:5000',
      'http://192.168.43.2:5000',
      'http://192.168.43.3:5000',
      'http://192.168.43.4:5000',
      'http://192.168.43.5:5000',
      'http://192.168.42.1:5000',
      'http://192.168.42.2:5000',
      'http://192.168.42.3:5000',
      'http://192.168.42.4:5000',
      'http://192.168.42.5:5000',
    ]);

    for (int i = 1; i <= 10; i++) {
      directIps.add('http://192.168.1.$i:5000');
      directIps.add('http://192.168.0.$i:5000');
      directIps.add('http://10.0.0.$i:5000');
      directIps.add('http://172.16.0.$i:5000');
      directIps.add('http://172.17.0.$i:5000');
      directIps.add('http://172.18.0.$i:5000');
      directIps.add('http://172.19.0.$i:5000');
    }

    for (var url in directIps) {
      if (await _testConnection(url, timeout: 800)) {
        return url;
      }
    }
    return null;
  }

  static Future<String?> _tryCommonAddresses() async {
    final commonAddresses = [
      'http://localhost:5000',
      'http://127.0.0.1:5000',
      'http://10.0.2.2:5000',
      'http://10.0.3.2:5000',
    ];

    for (var addr in commonAddresses) {
      if (await _testConnection(addr)) {
        return addr;
      }
    }
    return null;
  }

  static Future<String?> _discoverViaBroadcast() async {
    final completer = Completer<String?>();
    RawDatagramSocket? socket;

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final discoveryMessage = "DISCOVER_SAMARITAN_OCR_SERVER".codeUnits;

      final localIp = await _getLocalIpAddress();
      if (localIp != null) {
        final ipParts = localIp.split('.');
        if (ipParts.length == 4) {
          final broadcastAddr = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.255';
          final address = InternetAddress(broadcastAddr);
          socket.send(discoveryMessage, address, 5001);
        }
      }

      final commonBroadcasts = <String>[
        '255.255.255.255',
        '192.168.1.255',
        '192.168.0.255',
        '192.168.43.255',
        '192.168.42.255',
        '172.20.10.255',
        '10.255.255.255',
        '10.1.1.255',
      ];

      for (int i = 16; i <= 31; i++) {
        commonBroadcasts.add('172.$i.255.255');
      }

      for (int i = 0; i <= 255; i++) {
        commonBroadcasts.add('192.168.$i.255');
      }

      for (int i = 0; i <= 255; i++) {
        commonBroadcasts.add('10.$i.255.255');
      }

      final uniqueBroadcasts = commonBroadcasts.toSet().toList();

      for (var broadcast in uniqueBroadcasts.take(50)) {
        try {
          socket.send(discoveryMessage, InternetAddress(broadcast), 5001);
        } catch (e) {
          return "";
        }
      }

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket!.receive();
          if (datagram != null) {
            final response = String.fromCharCodes(datagram.data);
            if (response.startsWith('SERVER:')) {
              final parts = response.split(':');
              if (parts.length >= 2) {
                final serverIp = parts[1];
                final serverUrl = 'http://$serverIp:5000';
                if (!completer.isCompleted) {
                  completer.complete(serverUrl);
                  socket.close();
                }
              }
            }
          }
        }
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          completer.complete(null);
          socket?.close();
        }
      });

      return await completer.future;
    } catch (e) {
      socket?.close();
      return null;
    }
  }

  static Future<String?> _scanLocalNetwork() async {
    final localIp = await _getLocalIpAddress();

    final networksToScan = <String>[];

    if (localIp != null) {
      final ipParts = localIp.split('.');
      if (ipParts.length == 4) {
        networksToScan.add('${ipParts[0]}.${ipParts[1]}.${ipParts[2]}');
      }
    }

    networksToScan.addAll([
      '172.20.10',
      '192.168.43',
      '192.168.42',
    ]);

    for (int i = 0; i <= 20; i++) {
      networksToScan.add('192.168.$i');
    }

   for (int i = 16; i <= 31; i++) {
      networksToScan.add('172.$i.0');
      networksToScan.add('172.$i.1');
      networksToScan.add('172.$i.10');
      networksToScan.add('172.$i.20');
    }

    for (int i = 0; i <= 10; i++) {
      networksToScan.add('10.$i.0');
      networksToScan.add('10.$i.1');
    }

    final uniqueNetworks = networksToScan.toSet().toList();


    final ipsToScan = <String>[];

    for (var network in uniqueNetworks) {
      ipsToScan.add('$network.1');
      ipsToScan.add('$network.2');
      ipsToScan.add('$network.5');
      ipsToScan.add('$network.10');
      ipsToScan.add('$network.20');
      ipsToScan.add('$network.36');
      ipsToScan.add('$network.50');
      ipsToScan.add('$network.100');
      ipsToScan.add('$network.200');
      ipsToScan.add('$network.254');

      if (network.startsWith('172.20.10') ||
          network.startsWith('192.168.43') ||
          network.startsWith('192.168.42')) {
        for (int i = 1; i <= 30; i++) {
          ipsToScan.add('$network.$i');
        }
      }
    }

    final uniqueIps = ipsToScan.toSet().toList();


    int scanned = 0;
    for (var testIp in uniqueIps) {
      final testUrl = 'http://$testIp:5000';

      if (localIp != null && testIp == localIp) continue;

      scanned++;
      if (scanned % 100 == 0) {
      }

      if (await _testConnection(testUrl, timeout: 300)) {
        return testUrl;
      }
    }

    return null;
  }

  static Future<bool> _testConnection(String url, {int timeout = 800}) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = Duration(milliseconds: timeout);
      final request = await client.getUrl(Uri.parse('$url/health'));
      final response = await request.close();
      await response.drain();
      client.close();
      final success = response.statusCode == 200;
      if (success) {
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        if (interface.name.contains('lo')) continue;

        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      return "";
    }

    return null;
  }

  static Future<String> getNetworkType() async {
    final ip = await _getLocalIpAddress();
    if (ip == null) return 'Unknown';

    if (ip.startsWith('172.20.10.')) return 'iPhone Hotspot';
    if (ip.startsWith('192.168.43.')) return 'Android Hotspot';
    if (ip.startsWith('192.168.42.')) return 'Android Hotspot';
    if (ip.startsWith('192.168.')) return 'Home Network (192.168.x.x)';
    if (ip.startsWith('10.')) return 'Corporate Network (10.x.x.x)';
    if (ip.startsWith('172.')) {
      final parts = ip.split('.');
      if (parts.length >= 2) {
        final secondOctet = int.tryParse(parts[1]);
        if (secondOctet != null && secondOctet >= 16 && secondOctet <= 31) {
          return 'Private Network (172.16-31.x.x)';
        }
      }
      return 'iPhone Hotspot (172.x.x.x)';
    }

    return 'Unknown Network';
  }

  static Future<String?> promptForServerIp(BuildContext context) async {
    final TextEditingController ipController = TextEditingController();
    final TextEditingController portController = TextEditingController(text: '5000');

    final localIp = await _getLocalIpAddress();
    String suggestedBase = '192.168.1.';
    String networkHint = '';

    if (localIp != null) {
      if (localIp.startsWith('172.20.10.')) {
        suggestedBase = '172.20.10.';
        networkHint = 'iPhone Hotspot';
      } else if (localIp.startsWith('192.168.43.')) {
        suggestedBase = '192.168.43.';
        networkHint = 'Android Hotspot';
      } else if (localIp.startsWith('192.168.42.')) {
        suggestedBase = '192.168.42.';
        networkHint = 'Android Hotspot';
      } else if (localIp.split('.').length == 4) {
        suggestedBase = '${localIp.split('.')[0]}.${localIp.split('.')[1]}.${localIp.split('.')[2]}.';
        networkHint = await getNetworkType();
      }
    }

    Completer<String?> completer = Completer<String?>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.settings_ethernet, color: Colors.amber[700]),
              const SizedBox(width: 8),
              const Text('Manual Server Connection'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enter the IP address of the computer running the OCR server',
                          style: TextStyle(color: Colors.blue[700], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ipController,
                  decoration: InputDecoration(
                    labelText: 'Server IP Address',
                    hintText: 'e.g., 172.20.10.1 or 192.168.43.1',
                    prefixIcon: Icon(Icons.computer, color: Colors.amber[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Example: ${suggestedBase}36',
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portController,
                  decoration: InputDecoration(
                    labelText: 'Port Number',
                    hintText: '5000',
                    prefixIcon: Icon(Icons.settings_ethernet, color: Colors.amber[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Default port is 5000',
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (localIp != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.wifi, color: Colors.green[600], size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Your device IP: $localIp',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.network_check, color: Colors.blue[600], size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Network: $networkHint',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Make sure both devices are on the same network',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  'iPhone Hotspot: 172.20.10.x | Android: 192.168.43.x or 192.168.42.x',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ipController.dispose();
                portController.dispose();
                Navigator.of(dialogContext).pop();
                if (!completer.isCompleted) {
                  completer.complete(null);
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                String ip = ipController.text.trim();
                String port = portController.text.trim();

                if (ip.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid IP address'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                if (port.isEmpty) port = '5000';

                final serverUrl = 'http://$ip:$port';

                Navigator.of(dialogContext).pop();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text('Connecting to $serverUrl...'),
                        ],
                      ),
                    );
                  },
                );

                final isConnected = await _testConnection(serverUrl, timeout: 3000);

                if (context.mounted) {
                  Navigator.of(context).pop();
                }

                if (isConnected) {
                  if (!completer.isCompleted) {
                    completer.complete(serverUrl);
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not connect to $serverUrl\nMake sure the server is running'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                  if (!completer.isCompleted) {
                    completer.complete(null);
                  }
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    return completer.future;
  }
}