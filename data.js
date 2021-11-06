const fs = require('fs');
const RogueLand = artifacts.require('RogueLand');
const Register = artifacts.require('Register');
const NewRegister = artifacts.require('NewRegister');

module.exports = async function(callback) {
  try {
    //let rawdata = fs.readFileSync('events-main-9.json');
    let data = {};
    
    const contractRogueLand = await RogueLand.at('0xFDE9DAacCbA3D802BFCBAd54039A4B0DeAA48e85') //mainnet
    const contractRegister = await Register.at('0x5eFa33708a7688Fa116B6Cb3eC65D7fcE3c9f599') //testnet
	const contractNewRegister = await NewRegister.at('0x76f099cd22E737FC38f17FA07aA95dACe8e53e4e') //testnet

    for (let i=200; i<603; i++) {
		let master = await contractRogueLand.punkMaster(i)
		let balance = await contractRegister.balanceOf(master)
		if (balance.length == 0) {
			console.log(i, master, 0, 0)
		}
		if (balance.length == 1) {
			let n = Math.floor(balance[0]/1e18) + '000000000000000000'
			console.log(i, master, balance[0]/1e18, 0)
			if (balance[0]/1e18 > 0) {
				await contractNewRegister.award(master, 0, n)
				console.log('sent', n)
			}
		}
		if (balance.length == 2) {
			let n0 = Math.floor(balance[0]/1e18)
			let n1 = Math.floor(balance[1]/1e18/15*500)
			let n = (n0+n1) + '000000000000000000'
			console.log(i, master, balance[0]/1e18, balance[1]/1e18)
			if (n0 + n1 > 0) {
				await contractNewRegister.award(master, 0, n)
				console.log('sent', n)
			}
		}
	}
	
    //const transaction = await nft.getPastEvents('Transfer', { filter: {from: '0x0000000000000000000000000000000000000000'}, fromBlock: 0, toBlock: 'latest' })

    //fs.writeFileSync('data.json', golds);
    

  }
  catch(error) {
    console.log(error)
  }

  callback()
}