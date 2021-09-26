const fs = require('fs');
const Register = artifacts.require('Register');

module.exports = async function(callback) {
  try {
	  
	let rawdata = fs.readFileSync('vip.json');
    let vip = JSON.parse(rawdata);
  
    const contract = await Register.deployed()
    
    for (let i=0; i<vip.length; i++) {
      console.log(vip[i].id, vip[i].address)
      await contract.grantPunk(vip[i].id, vip[i].address)
    }
    
  }
  catch(error) {
    console.log(error)
  }

  callback()
}