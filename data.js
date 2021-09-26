const fs = require('fs');
const RogueLand = artifacts.require('RogueLand');

module.exports = async function(callback) {
  try {
    //let rawdata = fs.readFileSync('events-main-9.json');
    let data = {};
    
    const contract = await RogueLand.at('0xFDE9DAacCbA3D802BFCBAd54039A4B0DeAA48e85') //mainnet
    //const nft = await MyCollectible.at('0xe031188b0895afd3f3c32b2bf27fbd1ab9e8c9ea') //testnet

    let block = await web3.eth.getBlockNumber()
    console.log(block)

    const golds = await contract.getGoldsofAllPunk()
    //const transaction = await nft.getPastEvents('Transfer', { filter: {from: '0x0000000000000000000000000000000000000000'}, fromBlock: 0, toBlock: 'latest' })

    fs.writeFileSync('data.json', golds);
    

  }
  catch(error) {
    console.log(error)
  }

  callback()
}