```
sui client call --function subscribe --module subscribe \
--package 0x2751a228381c5456dc12dc27ce781739edc7ca31c0c54f85a14a34bcde94d4b4 \
--args  "0xe19e54a2117ff503249da2a1efa7b51244d120da0e54ba8380361a0625568101" \
0x6 \
0xe4827fdbc91c84966dda846e36a98b9a5cf344ff53ab3038fb778cea8cd604e3 \
0x423285acc44f7933cfe258a1d84d9a0401746fd5e72b6f53de0b2c722d91befd \
10000000000 \
1690772520290 \
1690772530290 \
10 \
--gas-budget 1000000000
G6gzRbERwCWQqFHXRHhMPsUonGoyVzoRdFcBHtugtMp7
```

```
sui client call --function subscribe_detail --module subscribe \
--package 0x2751a228381c5456dc12dc27ce781739edc7ca31c0c54f85a14a34bcde94d4b4 \
--args 0xe19e54a2117ff503249da2a1efa7b51244d120da0e54ba8380361a0625568101 1 \
--gas-budget 1000000000

sui client call --function timestamp --module subscribe \
--package 0x2751a228381c5456dc12dc27ce781739edc7ca31c0c54f85a14a34bcde94d4b4 \
--args 0x6 \
--gas-budget 1000000000


sui client call --function withdraw_and_trasfer --module subscribe \
--package 0x2751a228381c5456dc12dc27ce781739edc7ca31c0c54f85a14a34bcde94d4b4 \
--args  "0xe19e54a2117ff503249da2a1efa7b51244d120da0e54ba8380361a0625568101" \
0x6 \
1 \
--gas-budget 1000000000


sui client call --function spilt --module coin \
--package 0x2 \
--args  "0x97a608b4ede2a2db2b67ab4e0a94d57f8a5efe7162e88380d28cbe57e6c69ed6" \
0x6 \
0xe4827fdbc91c84966dda846e36a98b9a5cf344ff53ab3038fb778cea8cd604e3 \
--gas-budget 1000000
0x6993aee1ddf245d0852f9402a4ce10ffe72bb0191f8f8c476963e3de7c67d08c
```


