const fs = require('fs');
const Register = artifacts.require('Register');
const NewRegister = artifacts.require('NewRegister');

module.exports = async function(callback) {
  try {
    
    const register = await Register.at('0x5eFa33708a7688Fa116B6Cb3eC65D7fcE3c9f599') //mainnet
	const newRegister = await NewRegister.at('0x76f099cd22E737FC38f17FA07aA95dACe8e53e4e') //mainnet

    let block = await web3.eth.getBlockNumber()
    console.log(block)

    //const transaction = await market.getPastEvents('ItemBought', { fromBlock: 8264441, toBlock: 8268441 })
    const transaction = await register.getPastEvents('Use', { fromBlock: 6178600, toBlock: 6178899 })

    for (let i=0; i<transaction.length; i++) {
      console.log(transaction[i].returnValues.useId, transaction[i].returnValues.player, transaction[i].returnValues.id, transaction[i].returnValues.amount/1e18)
	  const accountInfo = await newRegister.accountInfo(transaction[i].returnValues.player)
	  console.log(transaction[i].returnValues.player, accountInfo.wallet)
    }

    
  }
  catch(error) {
    console.log(error)
  }

  callback()
}