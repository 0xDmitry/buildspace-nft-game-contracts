const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");

  const gameContract = await gameContractFactory.deploy(
    ["Cheems", "Doge", "Elon Musk"],
    [
      "Qmd7ephcDb2mujDnmjViVnvBr1em8h71gXg9gStYbJiFGx",
      "QmNwRFTL9sFuVHLzCJ7YYZYxPrzGJRN55EEGXU6qcWnQaM",
      "Qmcn87EzxXaZ4vFg4ZeWDGZUcShWUZcoa8raVNSaXSWifg",
    ],
    [50, 100, 250],
    [10, 20, 50],
    [5, 10, 25],
    "Mark Zuckerberg",
    "QmYYJLPn7vpTxhNhXvBP8EeCawABCqer3xxAyY8t7m2GYs",
    1000,
    10,
    80
  );

  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);

  let txn;
  txn = await gameContract.mintCharacterNFT(1);
  await txn.wait();

  txn = await gameContract.attackBoss();
  await txn.wait();

  txn = await gameContract.attackBoss();
  await txn.wait();

  console.log("Done!");
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
