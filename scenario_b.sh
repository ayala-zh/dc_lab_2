'EOF'
#!/bin/bash
echo "=== SCENARIO B: Concurrent Writes ==="
echo ""

echo "1. Clearing previous test key..."
python3 client.py --node http://172.31.0.182:8000 put concurrent_test "clear" > /dev/null 2>&1
sleep 2

echo "2. Checking initial state..."
echo "   Node A Lamport: $(python3 client.py --node http://172.31.0.182:8000 status 2>/dev/null | grep -o '\"lamport\": *[0-9]*' | head -1 | cut -d: -f2 | tr -d ' ')"
echo "   Node B Lamport: $(python3 client.py --node http://172.31.4.134:8001 status 2>/dev/null | grep -o '\"lamport\": *[0-9]*' | head -1 | cut -d: -f2 | tr -d ' ')"
echo "   Node C Lamport: $(python3 client.py --node http://172.31.0.144:8002 status 2>/dev/null | grep -o '\"lamport\": *[0-9]*' | head -1 | cut -d: -f2 | tr -d ' ')"

echo ""
echo "3. Sending concurrent PUTs (within 1 second)..."
echo "   PUT from Node A: x='value_A_ts_lower'"
python3 client.py --node http://172.31.0.182:8000 put concurrent_test "value_A_ts_lower" > /dev/null 2>&1 &

echo "   PUT from Node B: x='value_B_ts_higher'"
python3 client.py --node http://172.31.4.134:8001 put concurrent_test "value_B_ts_higher" > /dev/null 2>&1 &

echo "   Waiting for completion..."
wait
sleep 3  # Allow replication

echo ""
echo "4. Checking values and timestamps on all nodes..."
echo "   Node A:"
python3 client.py --node http://172.31.0.182:8000 get concurrent_test 2>/dev/null | python3 -m json.tool | grep -E '(value|ts|origin|lamport)'
echo ""
echo "   Node B:"
python3 client.py --node http://172.31.4.134:8001 get concurrent_test 2>/dev/null | python3 -m json.tool | grep -E '(value|ts|origin|lamport)'
echo ""
echo "   Node C:"
python3 client.py --node http://172.31.0.144:8002 get concurrent_test 2>/dev/null | python3 -m json.tool | grep -E '(value|ts|origin|lamport)'

echo ""
echo "5. Checking server logs for LWW decisions..."
echo "   (Look in Node A, B, C windows for 'LWW: Updated' or 'LWW: Rejected' messages)"
echo ""
echo "6. Final Lamport clocks:"
echo "   Node A: $(python3 client.py --node http://172.31.0.182:8000 status 2>/dev/null | grep -o '\"lamport\": *[0-9]*' | head -1 | cut -d: -f2 | tr -d ' ')"
echo "   Node B: $(python3 client.py --node http://172.31.4.134:8001 status 2>/dev/null | grep -o '\"lamport\": *[0-9]*' | head -1 | cut -d: -f2 | tr -d ' ')"
echo "   Node C: $(python3 client.py --node http://172.31.0.144:8002 status 2>/dev/null | grep -o '\"lamport\": *[0-9]*' | head -1 | cut -d: -f2 | tr -d ' ')"

echo ""
EOF