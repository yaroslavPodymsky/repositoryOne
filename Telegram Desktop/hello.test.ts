import { TonClient } from '@tonclient/core'
import { expect } from 'chai'
import { createClient } from './utils/client'
import pkgSafeMultisigWallet from '../ton-packages/SafeMultisigWallet.package'
import TonContract from './utils/ton-contract'
import pkgTest from '../ton-packages/Test.package'
import pkgWallet from '../ton-packages/Wallet.package'
import { utf8ToHex } from './utils/convert'
import { callThroughMultisig } from './utils/net'
import { assert } from 'chai'
import { equal } from 'assert'
import SafeMultisigWalletPackage from '../ton-packages/SafeMultisigWallet.package'

import { deployTest } from './deployWalletTest'
import { Test } from 'mocha'

const fs = require('fs')
describe('debot test', () => {
  let client: TonClient
  let smcSafeMultisigWallet: TonContract
  let smcTest: TonContract
  let aTest: TonContract

  before(async () => {
    client = createClient()
    smcSafeMultisigWallet = new TonContract({
      client,
      name: 'SafeMultisigWallet',
      tonPackage: pkgSafeMultisigWallet,
      address: process.env.MULTISIG_ADDRESS,
      keys: {
        public: process.env.MULTISIG_PUBKEY,
        secret: process.env.MULTISIG_SECRET,
      },
    })
    // console.log(0, smcSafeMultisigWallet);
  })

  it('deploy test', async () => {
    const keys = await client.crypto.generate_random_sign_keys()
    smcTest = new TonContract({
      client,
      name: 'Test',
      tonPackage: pkgTest,
      keys,
    })

    it('addrWallet test', async () => {
      const keys = await client.crypto.generate_random_sign_keys()
      aTest = new TonContract({
        client,
        name: 'aWallet',
        tonPackage: pkgTest,
        keys,
      })
    })
    //await smcTest.uploadWalletCode();

    await smcTest.calcAddress()

    console.log('Test address: ', smcTest.address)

    await smcSafeMultisigWallet.call({
      functionName: 'sendTransaction',
      input: {
        dest: smcTest.address,
        value: 2e9,
        bounce: false,
        flags: 2,
        payload: '',
      },
    })

    await smcTest.deploy({
      input: {
        rootData: {
          name: 'name',
          symbol: 'symbol',
          icon: 'icon',
          desc: 'desc',
          decimals: 0,
          totalSupply: 100,
        },
        pubkeyOwner: `0x0`,
        addrOwner: smcSafeMultisigWallet.address,
      },
    })
  }),
    it('set wallet code', async () => {
      await callThroughMultisig({
        client,
        smcSafeMultisigWallet,
        abi: pkgTest.abi, //какой контракт
        functionName: 'uploadWalletCode',
        input: {
          codeWallet: (
            await client.boc.get_code_from_tvc({ tvc: pkgWallet.image })
          ).code,
        },
        dest: smcTest.address, //какой конкретно контракт
        value: 10_000_000_000,
      })

      const res = await smcTest.run({
        functionName: '_codeWallet',
      })
    })
  it('deployWallet test', async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgTest.abi, //какой контракт
      functionName: 'deployWallet',
      input: {
        pubkeyOwner: `0x0`,
        addrOwner: smcSafeMultisigWallet.address,
        initialAmount: 50,
      },
      dest: smcTest.address, //какой конкретно контракт
      value: 10_000_000_000,
    })
    //assert.equal(deployTest(), true)
    //deployTest()
    // let res = deployTest()
    // console.log(res)
    assert.isTrue(deployTest())
  })
})
