import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/data/repositories/state_providers.dart';
import 'package:sbiv2/ai/engine/ai_coordinator.dart';
import 'package:sbiv2/ai/agent/agent_state.dart';

class AITestingLabScreen extends ConsumerStatefulWidget {
  const AITestingLabScreen({super.key});

  @override
  ConsumerState<AITestingLabScreen> createState() => _AITestingLabScreenState();
}

class _AITestingLabScreenState extends ConsumerState<AITestingLabScreen> {
  final TextEditingController _promptController = TextEditingController();
  
  // Diagnostic states
  String _dnsResult = 'Not Run';
  String _reachabilityResult = 'Not Run';
  String _apiKeyResult = 'Not Run';
  String _handshakeResult = 'Not Run';
  
  bool _isDnsRunning = false;
  bool _isReachabilityRunning = false;
  bool _isApiKeyRunning = false;
  bool _isHandshakeRunning = false;

  // Connection Testing States
  String _connTestStatus = 'Idle';
  bool _isConnTesting = false;

  // Response Testing States
  String _rawRequest = 'None';
  String _rawResponse = 'None';
  String _responseTime = 'N/A';
  String _toolCalls = 'None';
  String _responseError = 'None';
  bool _isPromptTesting = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _runDnsTest() async {
    setState(() {
      _isDnsRunning = true;
      _dnsResult = 'Resolving host...';
    });
    try {
      final result = await InternetAddress.lookup('generativelanguage.googleapis.com')
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          _dnsResult = 'Success\nIPs: ${result.map((e) => e.address).join(', ')}';
        });
      } else {
        setState(() {
          _dnsResult = 'Failed: No IP address resolved.';
        });
      }
    } catch (e) {
      setState(() {
        _dnsResult = 'Failed: $e';
      });
    } finally {
      setState(() {
        _isDnsRunning = false;
      });
    }
  }

  Future<void> _runReachabilityTest() async {
    setState(() {
      _isReachabilityRunning = true;
      _reachabilityResult = 'Connecting to port 443...';
    });
    try {
      final socket = await Socket.connect('generativelanguage.googleapis.com', 443, timeout: const Duration(seconds: 5));
      socket.destroy();
      setState(() {
        _reachabilityResult = 'Success\nConnected to host on port 443.';
      });
    } catch (e) {
      setState(() {
        _reachabilityResult = 'Failed: $e';
      });
    } finally {
      setState(() {
        _isReachabilityRunning = false;
      });
    }
  }

  Future<void> _runApiKeyTest() async {
    final apiKey = ref.read(geminiApiKeyProvider);
    if (apiKey.isEmpty) {
      setState(() {
        _apiKeyResult = 'Failed: No API Key configured.';
      });
      return;
    }
    setState(() {
      _isApiKeyRunning = true;
      _apiKeyResult = 'Validating key with Google API...';
    });
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        setState(() {
          _apiKeyResult = 'Success\nAPI Key is valid and authorized.';
        });
      } else {
        setState(() {
          _apiKeyResult = 'Failed\nStatus Code: ${response.statusCode}\nBody: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _apiKeyResult = 'Failed: $e';
      });
    } finally {
      setState(() {
        _isApiKeyRunning = false;
      });
    }
  }

  Future<void> _runHandshakeTest() async {
    final apiKey = ref.read(geminiApiKeyProvider);
    if (apiKey.isEmpty) {
      setState(() {
        _handshakeResult = 'Failed: No API Key configured.';
      });
      return;
    }
    setState(() {
      _isHandshakeRunning = true;
      _handshakeResult = 'Opening WebSocket handshake connection...';
    });
    try {
      final wsUrl = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey',
      );
      final ws = await WebSocket.connect(wsUrl.toString()).timeout(const Duration(seconds: 8));
      await ws.close();
      setState(() {
        _handshakeResult = 'Success\nWebSocket connection & handshake completed.';
      });
    } catch (e) {
      setState(() {
        _handshakeResult = 'Failed: $e';
      });
    } finally {
      setState(() {
        _isHandshakeRunning = false;
      });
    }
  }

  Future<void> _runAllDiagnostics() async {
    await _runDnsTest();
    await _runReachabilityTest();
    await _runApiKeyTest();
    await _runHandshakeTest();
  }

  Future<void> _testWebSocket() async {
    setState(() {
      _isConnTesting = true;
      _connTestStatus = 'Testing WebSocket Connection...';
    });
    await _runHandshakeTest();
    setState(() {
      _isConnTesting = false;
      _connTestStatus = _handshakeResult.startsWith('Success')
          ? 'WebSocket Test: PASSED ✅'
          : 'WebSocket Test: FAILED ❌';
    });
  }

  Future<void> _testRest() async {
    setState(() {
      _isConnTesting = true;
      _connTestStatus = 'Testing REST Reachability...';
    });
    await _runApiKeyTest();
    setState(() {
      _isConnTesting = false;
      _connTestStatus = _apiKeyResult.startsWith('Success')
          ? 'REST Test: PASSED ✅'
          : 'REST Test: FAILED ❌';
    });
  }

  Future<void> _testFullAgent() async {
    setState(() {
      _isConnTesting = true;
      _connTestStatus = 'Re-initializing coordinator stack...';
    });
    ref.read(aiCoordinatorProvider.notifier).updateApiKey(ref.read(geminiApiKeyProvider));
    await Future.delayed(const Duration(seconds: 2));
    final agentState = ref.read(agentStateProvider);
    setState(() {
      _isConnTesting = false;
      _connTestStatus = 'Agent State: ${agentState.status.name.toUpperCase()}\n'
          'WebSocket: ${agentState.webSocketStatus.toUpperCase()}\n'
          'REST: ${agentState.restStatus.toUpperCase()}';
    });
  }

  Future<void> _sendTestPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final apiKey = ref.read(geminiApiKeyProvider);
    final modelConfig = ref.read(aiModelConfigProvider);
    
    if (apiKey.isEmpty) {
      setState(() {
        _responseError = 'Error: Cannot send test prompt. API key is empty.';
      });
      return;
    }

    setState(() {
      _isPromptTesting = true;
      _rawRequest = 'Loading...';
      _rawResponse = 'Loading...';
      _responseTime = 'Calculating...';
      _toolCalls = 'None';
      _responseError = 'None';
    });

    const sysPrompt = "You are an AI Testing assistant. Answer the user prompt directly and concisely.";
    final requestBody = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'systemInstruction': {
        'parts': [
          {'text': sysPrompt}
        ]
      },
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 300,
      }
    };

    setState(() {
      _rawRequest = const JsonEncoder.withIndent('  ').convert(requestBody);
    });

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${modelConfig.restModel}:generateContent?key=$apiKey',
    );

    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      stopwatch.stop();
      setState(() {
        _responseTime = '${stopwatch.elapsedMilliseconds}ms';
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _rawResponse = const JsonEncoder.withIndent('  ').convert(decoded);
        });

        // Parse tool calls if any
        final candidate = decoded['candidates']?[0];
        final parts = candidate?['content']?['parts'] as List?;
        if (parts != null) {
          final toolList = parts.where((p) => p['functionCall'] != null).toList();
          if (toolList.isNotEmpty) {
            setState(() {
              _toolCalls = const JsonEncoder.withIndent('  ').convert(toolList);
            });
          }
        }
      } else {
        setState(() {
          _rawResponse = response.body;
          _responseError = 'HTTP Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _responseTime = '${stopwatch.elapsedMilliseconds}ms';
        _responseError = 'Exception thrown: $e';
      });
    } finally {
      setState(() {
        _isPromptTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentState = ref.watch(agentStateProvider);
    final modelConfig = ref.watch(aiModelConfigProvider);
    final apiKey = ref.watch(geminiApiKeyProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'AI Testing Lab & Diagnostics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Runtime Status section
          _buildSectionHeader('RUNTIME CONFIGURATION STATUS'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatusRow('Active Live Model', modelConfig.liveModel),
                  _buildStatusRow('Active REST Model', modelConfig.restModel),
                  _buildStatusRow('Active Transport', agentState.transportType.toUpperCase()),
                  _buildStatusRow('API Key Loaded', apiKey.isNotEmpty ? 'YES' : 'NO', 
                      valueColor: apiKey.isNotEmpty ? AppTheme.accentGreen : AppTheme.accentOrange),
                  _buildStatusRow('Connection Status', agentState.connectionStatus.toUpperCase(),
                      valueColor: agentState.connectionStatus == 'REST_ACTIVE' || agentState.connectionStatus == 'connected' 
                          ? AppTheme.accentGreen : Colors.amber),
                  _buildStatusRow('WebSocket Status', agentState.webSocketStatus.toUpperCase(),
                      valueColor: agentState.webSocketStatus == 'connected' ? AppTheme.accentGreen : AppTheme.accentOrange),
                  _buildStatusRow('REST Status', agentState.restStatus.toUpperCase(),
                      valueColor: agentState.restStatus == 'active' ? AppTheme.accentGreen : AppTheme.textSecondary),
                  _buildStatusRow('Session ID', agentState.sessionId ?? 'None'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Connection Testing section
          _buildSectionHeader('CONNECTION TESTING'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Run individual transport ping validations below:',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                        icon: const Icon(Icons.cable, size: 16),
                        label: const Text('Test WebSocket'),
                        onPressed: _isConnTesting ? null : _testWebSocket,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        icon: const Icon(Icons.http, size: 16),
                        label: const Text('Test REST'),
                        onPressed: _isConnTesting ? null : _testRest,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.aiTeal),
                        icon: const Icon(Icons.sync_alt, size: 16),
                        label: const Text('Test Full Agent'),
                        onPressed: _isConnTesting ? null : _testFullAgent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connection Test Log:', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          _connTestStatus,
                          style: AppTheme.monoStyle(fontSize: 11, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Diagnostics section
          _buildSectionHeader('DIAGNOSTICS & SYSTEM COMPLIANCE'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
                    icon: const Icon(Icons.troubleshoot),
                    label: const Text('Run Full Network Diagnostics'),
                    onPressed: _isDnsRunning || _isReachabilityRunning || _isApiKeyRunning || _isHandshakeRunning
                        ? null
                        : _runAllDiagnostics,
                  ),
                  const SizedBox(height: 16),
                  _buildDiagnosticTile(
                    title: 'DNS Resolution Test',
                    description: 'Resolves generativelanguage.googleapis.com',
                    result: _dnsResult,
                    isRunning: _isDnsRunning,
                  ),
                  const Divider(height: 16),
                  _buildDiagnosticTile(
                    title: 'Google Endpoint Reachability',
                    description: 'TCP Connection to generativelanguage.googleapis.com:443',
                    result: _reachabilityResult,
                    isRunning: _isReachabilityRunning,
                  ),
                  const Divider(height: 16),
                  _buildDiagnosticTile(
                    title: 'API Key Authorization',
                    description: 'Fetches authorized models using configured API Key',
                    result: _apiKeyResult,
                    isRunning: _isApiKeyRunning,
                  ),
                  const Divider(height: 16),
                  _buildDiagnosticTile(
                    title: 'WebSocket Handshake Connection',
                    description: 'Establishes secure WS connection & triggers handshake',
                    result: _handshakeResult,
                    isRunning: _isHandshakeRunning,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Response Testing section
          _buildSectionHeader('RAW RESPONSE & PAYLOAD INSPECTION'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Input a custom test prompt to inspect raw model payloads:',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promptController,
                          decoration: InputDecoration(
                            hintText: 'Enter test prompt...',
                            hintStyle: GoogleFonts.inter(fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _isPromptTesting ? null : _sendTestPrompt,
                        child: _isPromptTesting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Send'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTelemetryRow('Response Latency', _responseTime),
                  _buildTelemetryRow('Response Errors', _responseError, 
                      valueColor: _responseError == 'None' ? AppTheme.textPrimary : AppTheme.accentOrange),
                  const SizedBox(height: 12),
                  _buildCodeBlock('Raw Request Payload (JSON)', _rawRequest),
                  const SizedBox(height: 12),
                  _buildCodeBlock('Raw Response Payload (JSON)', _rawResponse),
                  const SizedBox(height: 12),
                  _buildCodeBlock('Detected Tool Calls', _toolCalls),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.monoStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticTile({
    required String title,
    required String description,
    required String result,
    required bool isRunning,
  }) {
    Color statusColor = AppTheme.textSecondary;
    if (result.startsWith('Success')) {
      statusColor = AppTheme.accentGreen;
    } else if (result.startsWith('Failed')) {
      statusColor = AppTheme.accentOrange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
              if (isRunning)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    result.split('\n')[0],
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(description, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
          if (result != 'Not Run' && result != 'Resolving host...' && result != 'Connecting to port 443...' && result != 'Validating key with Google API...' && result != 'Opening WebSocket handshake connection...') ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                result,
                style: AppTheme.monoStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String label, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: SingleChildScrollView(
            child: Text(
              code,
              style: AppTheme.monoStyle(fontSize: 10, color: AppTheme.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
          Text(
            value,
            style: AppTheme.monoStyle(fontSize: 11, fontWeight: FontWeight.bold, color: valueColor ?? AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
