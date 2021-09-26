const fs = require('fs');
const Register = artifacts.require('Register');

module.exports = async function(callback) {
  try {
    
    const register = await Register.at('0x5eFa33708a7688Fa116B6Cb3eC65D7fcE3c9f599') //mainnet

    let block = await web3.eth.getBlockNumber()
    console.log(block)

    //const transaction = await market.getPastEvents('ItemBought', { fromBlock: 8264441, toBlock: 8268441 })
    const transaction = await register.getPastEvents('Use', { fromBlock: 6074100, toBlock: 6074399 })

    for (let i=0; i<transaction.length; i++) {
      console.log(transaction[i].returnValues)
    }

    
  }
  catch(error) {
    console.log(error)
  }

  callback()
}