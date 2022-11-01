import React, { useState } from "react";
import { ethers } from 'ethers';
import contractAbi from './contract/Egame.json';

function App() {
  let contractEgame = "0x54a30D15f123678db68fe93499d3165d999Db665";
  const abi = contractAbi.abi;

	const [defaultAccount, setDefaultAccount] = useState(null);
	const [connButtonText, setConnButtonText] = useState('Connect Wallet');

	const [scorePlayer, setScorePlayer] = useState(null);
  const [tokenPlayer, setTokenPlayer] = useState(null);

	const [provider, setProvider] = useState(null);
	const [signer, setSigner] = useState(null);
	const [contract, setContract] = useState(null);

  const conncetWalletHandle = () => {

    if (window.ethereum && window.ethereum.isMetaMask) {

			window.ethereum.request({ method: 'eth_requestAccounts'})
			.then(result => {
				accountChangedHandler(result[0]);
				setConnButtonText('Wallet Connected');
			})
			.catch(err => {
				console.error(err)
			
			});

		} else {
			console.log('Need to install MetaMask');
		}
  }

  // update account, will cause component re-render
	const accountChangedHandler = (newAccount) => {
		setDefaultAccount(newAccount);
		updateEthers();
	}

  //const chainChangedHandler = () => {
		// reload the page to avoid any errors with chain change mid use of application
	//	window.location.reload();
	//}

  const updateEthers = () => {
		let tempProvider = new ethers.providers.Web3Provider(window.ethereum);
		setProvider(tempProvider);

		let tempSigner = tempProvider.getSigner();
		setSigner(tempSigner);

		let tempContract = new ethers.Contract(contractEgame, abi, tempSigner);
		setContract(tempContract);	
	}

	const setClaimScore = async (event) => {
		event.preventDefault();
		console.log('claiming ' + event.target.setText.value + ' scores');
		await contract.claimScore(event.target.setText.value);
	}

  const setTokenClaim = async () => {
		console.log('claiming ' + {getTokenPlayer} + ' tokens');
		await contract.claimToken();
    setTokenPlayer(await contract.getToken())
	}

	const getScorePlayer = async (addressPlayer) => {
    addressPlayer.preventDefault();
		let val = await contract.getScore(addressPlayer);
		setScorePlayer(val);
	}

  const getTokenPlayer = async (addressPlayer) => {
    addressPlayer.preventDefault();
		let val = await contract.getToken(addressPlayer);
		tokenPlayer(val);
	}

  return (
    <div>
      <h1>EGame Score</h1>
      <button onClick={conncetWalletHandle}>{connButtonText}</button>
      <p>Adress: {defaultAccount}</p>
      <form onSubmit={setClaimScore}>
				<input id="setText" type="text"/>
				<button type={"submit"}> Claim Score </button>
			</form>
      <form>
        <button onClick={getScorePlayer}>Check score</button>
        <p>Your Score {scorePlayer}</p>
      </form>
      <form>
        <button onClick={getTokenPlayer}>Check score</button>
        <p>Your Score {tokenPlayer}</p>
      </form>
      <hr/>
      <button onClick={setTokenClaim}>
        Claim Token
      </button>
    </div>
  );
}

export default App;
