//ethers@5.7.0
const ethers = require("ethers");

const privateKey =
  "0x99b07ead3e50245003d7c1c6e5ac5fcc5ac15fd2ddfda22a6a4f423b90e61143";
const signingKey = new ethers.utils.SigningKey(privateKey);

const hash =
  "0x4030d48978ee5c7e7592f63f58f6dfe9eb92ee7a96501852b2e2889fc4d10bfb";

const signature = signingKey.signDigest(hash);

console.log(signature);
