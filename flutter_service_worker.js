'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "8fea3b4892c55b296ec16993bc8b9c94",
".git/config": "784f0a70e390c41c5dd3c6bba9582abb",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "c3cbdda69b58347d8e4885f5a3b332cb",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "9be7643456dbcfb43fcdd207ecd8d481",
".git/logs/refs/heads/gh-pages": "81f9695076de9f5576a68d6df2fbbaa5",
".git/logs/refs/remotes/origin/gh-pages": "d9fd2c7a102399252b4ab73f468c56f3",
".git/objects/02/bcd8ce49c7113671f8a23596ec4c9e4386fdfd": "79d3cea6325bdc23b7f746fd5cc27f74",
".git/objects/03/2fe904174b32b7135766696dd37e9a95c1b4fd": "80ba3eb567ab1b2327a13096a62dd17e",
".git/objects/03/81198d346fb44a3dfa9c6c87a025a024e375c5": "d4ac5eb83a364df2077e328979dad055",
".git/objects/0c/31e9f57cca4d7f0567aa0d39baba1f54c1d160": "e707d1457afda78508b983a98fccfa56",
".git/objects/0f/6fe709cdd408727185b45cc8522e46a66f8060": "82d23477173a06d0c0bad41cacd81627",
".git/objects/13/2cca1602beabba6145d103cca0592c13f3a39c": "663f9978261a68d6c79b605bd81848f0",
".git/objects/16/a1560e8de30e53bed2b05f643b2e4a902a975f": "78b5c5849e5a85d82ca4aff8d2ab4207",
".git/objects/17/1b5aa085c80961c70a544e973faf38051c2936": "7574b6b3c74ac611bc1a10745c03c335",
".git/objects/18/5c02f60eb31071dac67842acfaef6fa37eee12": "e30ab2853f8c908b51a7ccae91720469",
".git/objects/19/a509641c5391eb277a09cc9583858a22758b66": "d648919d2b8f000b6e258dd4a88b7cca",
".git/objects/1a/8739fe6e4d25483824131087df49e5e05932ff": "313e88351c22f7797ae3584ba38be6ca",
".git/objects/1b/4ba271f0f944905ee55f88e507286842dc7113": "260485381232f3de4fae9e09f2f8fa71",
".git/objects/1b/c8da11f9c1723c367fd68064758ad77adfccaf": "75c242066acad64b8f9f43df9922157a",
".git/objects/1b/e558e06cca2ff0698480e382f799ab507d2f73": "a70d06ca0bd0b3c8c54c07ea22baae57",
".git/objects/1c/cebccfea89f68f413274a8ec1c2a9bb2c3648d": "3cec76446e1c8f2d0fdfb38943c47211",
".git/objects/1d/a994227c051cf3247b3850a63bafdce571ab1b": "92e351a3e4268b35e06cc9958614c7a3",
".git/objects/1e/797c2a6baf97a9ecf606c700abbbc3a8ec196b": "2f29b491d152b3205bb89ee0509fab2f",
".git/objects/23/454ff1d8263a83ded1adf367f473d7dc44e2c8": "a31f565049f831eb12c33ada53eff670",
".git/objects/23/dbbef7ad33589162417e100093cea56d8dab03": "d3224be8b2ae5e0bb32090a116a2b104",
".git/objects/24/d1291021f64dc522628bf45165434c1b1e5219": "d78916a0f70807e4974727723cf8ec56",
".git/objects/29/83c83a1e6b748be2c830966d823bfa201b1608": "ba39895dae0109b78041beb1a36b6f8c",
".git/objects/2d/a579a2024af26097aa15714257e31b6ae4017d": "b63b105f92412029b7f0f879e8e0fc35",
".git/objects/32/7be1897e575bf99636ec6f697de2d9a6aa779f": "d77ccfe1cdb91fc887e06ef110e709fb",
".git/objects/33/31d9290f04df89cea3fb794306a371fcca1cd9": "e54527b2478950463abbc6b22442144e",
".git/objects/35/026249627c26b3f77672bdd95325379a39a340": "b5a73416c8d1580fec865170ee3ce66f",
".git/objects/35/96d08a5b8c249a9ff1eb36682aee2a23e61bac": "e931dda039902c600d4ba7d954ff090f",
".git/objects/36/109bacf238cc97aa747ad4e8d0e27b51e56c30": "a36b84caa1ab50261fe153c02d6fc4de",
".git/objects/36/423c33fbce703402a0e4c11ad763f4e4d13754": "cf027388eecf55177ca794f96e89279a",
".git/objects/3b/387eb859cae066d971ec9fe1dcb9b0263eb6f7": "ea3ee9828934533e4cb6809bd8be8b97",
".git/objects/3f/348341cb5b76e13dbed0555a58e964d71f8613": "457bf88de0a6a6e3a9d97b25852df5f2",
".git/objects/40/0d1000d73ca1bca9a7d4fda140d2601b6aa913": "643554cf20ec65ea6bef186fd8281ec4",
".git/objects/40/1184f2840fcfb39ffde5f2f82fe5957c37d6fa": "1ea653b99fd29cd15fcc068857a1dbb2",
".git/objects/42/97f173868bae0333bd1089d73df42c5e7421c2": "893d687e4c66ba4424b7f0a45a18f726",
".git/objects/43/9a9f03bbf3750e778b9c6310654c4381dbbf10": "f6968aad51c3ffdd0ce7b023b1fc006c",
".git/objects/43/bc24f46ce7030d27f161434ca83c66d9ab64e8": "08adecae2ba6fcea3f664db37a33d76e",
".git/objects/4f/02e9875cb698379e68a23ba5d25625e0e2e4bc": "254bc336602c9480c293f5f1c64bb4c7",
".git/objects/53/0fa053bde5a920e7725c8357c6f00554bcde01": "64613e711cb7cf9704f3fb8d29af2f09",
".git/objects/57/7946daf6467a3f0a883583abfb8f1e57c86b54": "846aff8094feabe0db132052fd10f62a",
".git/objects/5a/f42d473356441cc19d900ed5f8bc35d065edcb": "d1b2bbcee63e63e0ed8de32a8c84f5ac",
".git/objects/5f/bf1f5ee49ba64ffa8e24e19c0231e22add1631": "f19d414bb2afb15ab9eb762fd11311d6",
".git/objects/64/5116c20530a7bd227658a3c51e004a3f0aefab": "f10b5403684ce7848d8165b3d1d5bbbe",
".git/objects/65/9cda3bd1fbb89b1c1e26f0f3040a805602a88d": "0bc3ee8793200e2625ee4a65c23f16bb",
".git/objects/66/193c3c1f6677a4f2023380f1dab6decf485950": "baf7b4923857631b7358a686080eaefd",
".git/objects/69/94e5e5b65d96d34500bfe964a22d1eab7b8dee": "25043f232726ea1205d2fe23298779db",
".git/objects/6c/b4656c66c4938d3620d3a4cac76395030d136e": "098e189fa7793cda659b5e00ee5b96e8",
".git/objects/6d/10b333a0e9162bbe0c4aeea1a3867a7a78809c": "161a0386d2a09688253030ca6ad4b9f6",
".git/objects/6d/df60e80bfd98fa65636baf457d425b2564235f": "88c16d50a238ab14ec85853ac5ffa6d9",
".git/objects/6e/e97b889596da4b427f4230fe5ccf1b0a098de7": "215f5cda7eeb0c332acf3e1db32af270",
".git/objects/6f/32f0b02a07906914ea3f0f3dbd7ed1a9abb4aa": "ab2a0aefa527dfd0d7f6ccb6f25b58d1",
".git/objects/6f/cd5f964d3c54b1a94ed4ab2311fa3cc0d9f493": "3c7d2479adf529968467ad3a47182a6c",
".git/objects/70/92a880bbdbb22299a7bff0f2fa7879a8f1ad2d": "2f06ad9cf795b58fd2bdce97ffbb1a6b",
".git/objects/74/0dcd57466523b7148e8e804c19c384ba31c6e8": "ba7777bfaae715d94cd45f4ae0ccdc7d",
".git/objects/75/29d1b9051a6783bace1039d864d19bb8715a05": "7ee5d6f9a393cab37c71661265b9a884",
".git/objects/75/608c6642d677d8e05f46a3d3bd3669db806f53": "90832fa6d086cfa74605a75e79c0947c",
".git/objects/78/2442a7478bf6eb419a17f3b9cbc07383570729": "a7a84f550f9696e484a92baf6b0a2867",
".git/objects/7a/3fe5fcb22bdaae52e07a4f3d98e7f090c111ca": "65acf28fffaf2702fb7bd4058833bf47",
".git/objects/7e/3bb2f8ce7ae5b69e9f32c1481a06f16ebcfe71": "4ac6c0fcf7071bf9fc9c013172f9996f",
".git/objects/80/ff64eca9a251e05588220c2f359932c6784b6a": "1654a4bb0c9b1edc086d86819d89a698",
".git/objects/81/8798d92fb09ba5bc6f26317bc90b6dcd0903b1": "ce0fe14e0bd75775a82b519f64ae6712",
".git/objects/81/afeea53c93ec9135834ae9b9b90066a065134e": "574c9e28d7ef998b0516f8cca89df7e6",
".git/objects/81/d1147ec31da0c06864914b1323bfcd5df6b18d": "137b027a6caf7319fa9f46e078e09af7",
".git/objects/83/3b74d39113ade3c3bcd3985001d16627147113": "00bd1202953037f3228f0343ba8abb18",
".git/objects/86/04aee4a81785c1261b7d03b7a4c6532e0b4857": "4533cd5793bde0b3ea53c71a803138f6",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/51a9b155d31c44b148d7e287fc2872e0cafd42": "9f785032380d7569e69b3d17172f64e8",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8b/ca6488560a408a535ed24b937ac5449d0e41a0": "9eabf3647688417f97ba14f125d5820d",
".git/objects/8e/d8d79cb8edd3481f253a8ac5d15bd445370c0f": "53ea3559ca37b34f31391ff37b91c6eb",
".git/objects/8e/edb64afa4971743d2c42964c8852ac29da1ef4": "892f62ec7ac2531cbb8938c75e27c788",
".git/objects/91/4a40ccb508c126fa995820d01ea15c69bb95f7": "8963a99a625c47f6cd41ba314ebd2488",
".git/objects/92/9a0938bf3c19092cae78cb3dbd2d081798773d": "e112b2ba46629f474d0e5efea25b3931",
".git/objects/98/d7b0d5ad30f57eeca2ad3fe619d16f96c6f8a7": "f313231ccf768748921c76cf9717ee12",
".git/objects/9d/7cf220f98402e6908795046cd3c124886fc54a": "2fe461ce38db262ea17658f27acd3579",
".git/objects/9d/f543aa9429659d743e99ee922b512fa11a4ca0": "c4bb50e14bc82a5b16646ffa8b85949d",
".git/objects/9f/623e0021bad8480f902921ff58bed6e46ca179": "d93a92f49f2ce2460ffa9e43670243dd",
".git/objects/9f/b22513e4f44f3364698a592791654530032018": "31022f51b8a397e3f28524ad0236827a",
".git/objects/a2/8d58ccec9311aa6c22a4de12118c79968cc804": "daf492c9f3a531b49adccafd3be02e2b",
".git/objects/a5/536f5d54791d4127dbd08383fa219daa0f03c1": "d07b61d9a02fa8e1cb2ce9da4fe7fd45",
".git/objects/a5/de584f4d25ef8aace1c5a0c190c3b31639895b": "9fbbb0db1824af504c56e5d959e1cdff",
".git/objects/a6/e504709f43aab0ab597778467c7f65738e2a57": "c2e2a23357c4a7ed9f9bb2c8156faa07",
".git/objects/a8/8c9340e408fca6e68e2d6cd8363dccc2bd8642": "11e9d76ebfeb0c92c8dff256819c0796",
".git/objects/a9/cde17e65c01315305b7723736704e45c52a2f4": "55c21dea51f7e6db1b42851124faeed6",
".git/objects/ab/34b70cdbf8c98594c10332668d7c3cf0c43d76": "e1c730511cb8f7b10d1af69f333e9d7c",
".git/objects/ae/ff7c299fe34b9cf00aba66925a358e4c398a35": "bbf2d4b5e4e39138f9aac005d9931de6",
".git/objects/b2/b8fc5d09bb245ad0f742a21f5539de607e040e": "dc6f80e5bcd0e78821d36ec746a669c8",
".git/objects/b3/ee7bd849e0a226b187d01aedb4b990a2edce0a": "61a99aecc29f0340cf2ca387c036c25f",
".git/objects/b4/0ce774d1f6a9e0d13acd68aa17fa22b1f6b201": "b4c3f9e730e8f23f84954f8405f47377",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b7/c71212b93eae7e65dff07ddb642c925b6b20ea": "914ef7c653d55328d48db89217615ca1",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/aedcd49d084a7a02213f4a5f7d9f5df090b900": "0fc24272109768e4178ca81b71f907f1",
".git/objects/bd/aea9d3ba0b3d73d12c51ec5e481f1667b1d4f5": "17cf53bc2c1b229c07d6a90fd0f92255",
".git/objects/c0/5492fff5215db58f87e0993dcb2fbec2775db5": "bba57fc207f33d49e7fb0737dcb99bb1",
".git/objects/c0/96473e92af3dafcd31220be7d17e1206bec24d": "be898f92f3e86bfa0dd2bf15f6cc3ff9",
".git/objects/c3/abaefb284004df30fc3017c7fa7985b412405d": "d933c20829aeab2af7aef2ea8dad1a69",
".git/objects/c3/ccd4915848679df617a03dcde70ed71646de27": "21d83b3603d97d7297fd1e4cf14b9b14",
".git/objects/c4/2c04a08bb83a131cd458500d8415477e98d722": "c57516287bf9ff858afa43a2c88390bf",
".git/objects/c7/1c549d3f3c6d4c48d601c21efbdca7d3596ead": "441f41a6f253615b26d6d1fec3f7b6b9",
".git/objects/cc/38d6a3ade92badbe08c355bbf5b7f75eeff109": "f0b677d1e1ff5211e9683d441b4677ab",
".git/objects/d0/6487b971dbec01f78731fa0cbcbcea64dc21a7": "250e0ab9c502b8d1ffd76643591e7fd0",
".git/objects/d2/69187b4b85e38658666ca001b7ac87b838a4d7": "912c31450a3daf70e86a3e1bd42181e9",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d5/1221af2b255560bcb313fbcc22cc43167c173f": "d53872b2d53be94338bfdef44cde6386",
".git/objects/d6/29e984895d8ff4442fe7bdce1ed4dc754730ca": "b1752d2154478a6b9d06498cbb941b7d",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d8/d4f0df94b30ad6982233d365029e03dad39f29": "e51cb09429b5fe95e79f6c51fcf716ed",
".git/objects/d8/fcd000237f7e99f714897d985a8d4d0a30a2fc": "cffdc5da45a45c165ed585d3c8e3bc7d",
".git/objects/d9/3952e90f26e65356f31c60fc394efb26313167": "1401847c6f090e48e83740a00be1c303",
".git/objects/dd/2842b5494b362eb6dec85d0641b35d8e864687": "b861c97efdafb69fa65a74624c6792ce",
".git/objects/e1/c25a01c0c38619225d41b84d76f9d1fa42eeb2": "e5ca453c27658fcceef72e339db0462c",
".git/objects/e1/f34bd035605595c4b20402571a8c1d8bc6d6cb": "17764ac8805517cfdf7fd7f6571d990f",
".git/objects/e4/b785ba4660110c037677827147a3ad50d452c8": "d86a45e8263eb8614b99d1dd0847e4e0",
".git/objects/e5/8e966e13f2e26e2ec2c80edc4c9921831e3588": "14ae51ca35bc7b300f7be6b16dd47cb0",
".git/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391": "c70c34cbeefd40e7c0149b7a0c2c64c2",
".git/objects/e7/0c357377a97f8c9bba36112495861b17ab154e": "7b3cb3e4245161ab4df101897b54c395",
".git/objects/e8/5b791a5e37dbd1fb593c12167496e37cc0d88a": "ff9056065526f54604e675118ae9a8be",
".git/objects/e8/8bc4af435555c98682b8b4b615802ac5760bfe": "4d70ec80381d2974b105dba0ddf51fd3",
".git/objects/e8/eb6a6984a15f48a6e807bd52fd1bbad53aa2ba": "3aa5b7a13999abe90f8b956b53549d22",
".git/objects/e9/c34d6dd9789a7bfbd5801058fa4d323ae192a1": "acf09ac3c1ee32587c2b8e9be970e3a8",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ef/9ed1b441235bc6c5d0478f58876def61a02ae7": "d538592bb1283997a904bcaf83b77536",
".git/objects/ef/b875788e4094f6091d9caa43e35c77640aaf21": "27e32738aea45acd66b98d36fc9fc9e0",
".git/objects/f0/f56c98c2958ebcc96f8da9f3cd9d6dcbdf52e3": "5eb933dd529bb632d4ddceed7a57d7e9",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f3/709a83aedf1f03d6e04459831b12355a9b9ef1": "538d2edfa707ca92ed0b867d6c3903d1",
".git/objects/f7/3d68126331e9a60ef8ba63213c13c4ff2ca982": "3a2fadf013acff0d2babf9395b96e7cb",
".git/refs/heads/gh-pages": "9a951316673c28265e8afd63a51dabb2",
".git/refs/remotes/origin/gh-pages": "9a951316673c28265e8afd63a51dabb2",
"assets/AssetManifest.bin": "2a65e5962609c80f3ea355edb00c5048",
"assets/AssetManifest.bin.json": "29bba9841f34b67ac0226ab0cd779053",
"assets/AssetManifest.json": "d1f68d6ae43ebfba66471205d5a7b20a",
"assets/assets/fonts/Roboto-Black.ttf": "dc44e38f98466ebcd6c013be9016fa1f",
"assets/assets/fonts/Roboto-BlackItalic.ttf": "792016eae54d22079ccf6f0760938b0a",
"assets/assets/fonts/Roboto-Bold.ttf": "8c9110ec6a1737b15a5611dc810b0f92",
"assets/assets/fonts/Roboto-BoldItalic.ttf": "e85cb1c48a3695009621fdb836eb22e9",
"assets/assets/fonts/Roboto-ExtraBold.ttf": "27fd63e58793434ce14a41e30176a4de",
"assets/assets/fonts/Roboto-ExtraBoldItalic.ttf": "80b61563f9e8f51aa379816e1c6016ef",
"assets/assets/fonts/Roboto-ExtraLight.ttf": "83e5ab4249b88f89ccf80e15a98b92f0",
"assets/assets/fonts/Roboto-ExtraLightItalic.ttf": "41c80845424f35477f8ecadfb646a67d",
"assets/assets/fonts/Roboto-Italic.ttf": "1fc3ee9d387437d060344e57a179e3dc",
"assets/assets/fonts/Roboto-Light.ttf": "25e374a16a818685911e36bee59a6ee4",
"assets/assets/fonts/Roboto-LightItalic.ttf": "00b6f1f0c053c61b8048a6dbbabecaa2",
"assets/assets/fonts/Roboto-Medium.ttf": "7d752fb726f5ece291e2e522fcecf86d",
"assets/assets/fonts/Roboto-MediumItalic.ttf": "918982b4cec9e30df58aca1e12cf6445",
"assets/assets/fonts/Roboto-Regular.ttf": "303c6d9e16168364d3bc5b7f766cfff4",
"assets/assets/fonts/Roboto-SemiBold.ttf": "dae3c6eddbf79c41f922e4809ca9d09c",
"assets/assets/fonts/Roboto-SemiBoldItalic.ttf": "2d365b1721b9ba2ff4771393a0ce2e46",
"assets/assets/fonts/Roboto-Thin.ttf": "1e6f2d32ab9876b49936181f9c0b8725",
"assets/assets/fonts/Roboto-ThinItalic.ttf": "dca165220aefe216510c6de8ae9578ff",
"assets/assets/fonts/Roboto_Condensed-Black.ttf": "b8e3ed03047190a170b330b99cb497cf",
"assets/assets/fonts/Roboto_Condensed-BlackItalic.ttf": "77716aa38d5bfb3b7a8707797e6d6d65",
"assets/assets/fonts/Roboto_Condensed-Bold.ttf": "07bb72eb5189e2f32a17031e20535777",
"assets/assets/fonts/Roboto_Condensed-BoldItalic.ttf": "a716b7548d0a9e24b5e165906c017f73",
"assets/assets/fonts/Roboto_Condensed-ExtraBold.ttf": "e7921919c3021ad88323d48eb9294917",
"assets/assets/fonts/Roboto_Condensed-ExtraBoldItalic.ttf": "17772988c821639e9fe36044d6931208",
"assets/assets/fonts/Roboto_Condensed-ExtraLight.ttf": "cf9840bb59a0b4ef1f6441efde262ec0",
"assets/assets/fonts/Roboto_Condensed-ExtraLightItalic.ttf": "2c2c1df1100801d8a4b345d27f302980",
"assets/assets/fonts/Roboto_Condensed-Italic.ttf": "58ab0145561cf8b4782eea242cb30f5b",
"assets/assets/fonts/Roboto_Condensed-Light.ttf": "0f3de38ef164b0a65a8a0a686e08bbff",
"assets/assets/fonts/Roboto_Condensed-LightItalic.ttf": "d86a4886b06b3be02dd8c06db6c7b53d",
"assets/assets/fonts/Roboto_Condensed-Medium.ttf": "b9f98617f7bc110311f054d264f43b58",
"assets/assets/fonts/Roboto_Condensed-MediumItalic.ttf": "a887fedb5da68c3987dcaf272f685228",
"assets/assets/fonts/Roboto_Condensed-Regular.ttf": "6f1c323492d1266a46461cbc57101ad4",
"assets/assets/fonts/Roboto_Condensed-SemiBold.ttf": "e9bd6495779750596421effa84fdd4f5",
"assets/assets/fonts/Roboto_Condensed-SemiBoldItalic.ttf": "9f8f19b06543707a34bda741211fd833",
"assets/assets/fonts/Roboto_Condensed-Thin.ttf": "38ca91dbce841a3c3c20a3024a00fb93",
"assets/assets/fonts/Roboto_Condensed-ThinItalic.ttf": "66aeec1eb99fd707bbda2c23c0d88dbd",
"assets/assets/fonts/Roboto_SemiCondensed-Black.ttf": "4e83f16b2aae530ed5a9eea2c6fcba0e",
"assets/assets/fonts/Roboto_SemiCondensed-BlackItalic.ttf": "cee6c277748569381168fa4873f17951",
"assets/assets/fonts/Roboto_SemiCondensed-Bold.ttf": "4bc60797786e604a69c1b81a60231b6a",
"assets/assets/fonts/Roboto_SemiCondensed-BoldItalic.ttf": "11ddd56e0fc47673960de04be0ddaf6d",
"assets/assets/fonts/Roboto_SemiCondensed-ExtraBold.ttf": "cd66a60e5be720ca2c368e6b60348cd4",
"assets/assets/fonts/Roboto_SemiCondensed-ExtraBoldItalic.ttf": "76b49fa5b22fb20fd69561f17237e80d",
"assets/assets/fonts/Roboto_SemiCondensed-ExtraLight.ttf": "83c6c6b25720032a079c86b8244ece58",
"assets/assets/fonts/Roboto_SemiCondensed-ExtraLightItalic.ttf": "c5105f6fbcd6f492a2a6f99f92936d22",
"assets/assets/fonts/Roboto_SemiCondensed-Italic.ttf": "5cae5cd3f40c671315aea0e55f8aa469",
"assets/assets/fonts/Roboto_SemiCondensed-Light.ttf": "7f35ecca19fa7286023e6d5d29d98fee",
"assets/assets/fonts/Roboto_SemiCondensed-LightItalic.ttf": "ee86d3beb5d7e6f711f0f12f09179d48",
"assets/assets/fonts/Roboto_SemiCondensed-Medium.ttf": "ec198bede12e04919f81c2deabbfddfe",
"assets/assets/fonts/Roboto_SemiCondensed-MediumItalic.ttf": "4404af13d7c2b95be24b367e5dfaa726",
"assets/assets/fonts/Roboto_SemiCondensed-Regular.ttf": "1a494bea2b882849db6c932aee6a4302",
"assets/assets/fonts/Roboto_SemiCondensed-SemiBold.ttf": "4cd0ff27a44b68f74262ec5d63d9f304",
"assets/assets/fonts/Roboto_SemiCondensed-SemiBoldItalic.ttf": "60a345becd1b883beef9d02bbb655af6",
"assets/assets/fonts/Roboto_SemiCondensed-Thin.ttf": "4f2191b28015879bcd1836c2d03b9ac5",
"assets/assets/fonts/Roboto_SemiCondensed-ThinItalic.ttf": "b1b3f970c13ebd8f93345d10d6ac3626",
"assets/assets/sounds/alarmsound.py": "b961f6e33f91438e13368fb942571336",
"assets/assets/sounds/alarm_sound.wav": "d29d8579d681ea6b9881f81770a55214",
"assets/assets/sounds/silent.mp3": "096d4bea387b84e068e48f2bde360ec5",
"assets/FontManifest.json": "8f8e647b278cbf78c0517ff998b6d1a2",
"assets/fonts/MaterialIcons-Regular.otf": "9fbeee18cd16c8ae3c671409230b1037",
"assets/NOTICES": "459871483e82ba072784235af815830b",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "1db4a4bc184db1c1b8d4b030b60b2adf",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "98ef39e69cdc67a720d16c6bb47a1aa9",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "390fcf07967a16f3e53dc079c9a876f1",
"/": "390fcf07967a16f3e53dc079c9a876f1",
"main.dart.js": "4456aee7b7f6047e7a487569a1ee03d8",
"manifest.json": "7ca990b9dd82555b860195b19c4b2fad",
"version.json": "6b200d5e6388330029e5b030c57ef6d2"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
