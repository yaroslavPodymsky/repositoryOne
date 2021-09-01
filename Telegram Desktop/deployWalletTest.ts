import { assert } from 'chai'
import { callThroughMultisig } from './utils/net'
import TonContract from './utils/ton-contract'
import { TonClient } from '@tonclient/core'
import pkgSafeMultisigWallet from '../ton-packages/SafeMultisigWallet.package'
import pkgTest from '../ton-packages/Test.package'

let smcTest: TonContract
let client: TonClient
let smcSafeMultisigWallet: TonContract

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

function walletSpecified(): boolean {
  if (
    smcSafeMultisigWallet.address != '0x0' ||
    smcSafeMultisigWallet.keys.public != '0x0'
  ) {
    return true
  } else {
    return false
  }
}

function ownerDist(initialAmount): boolean {
  if (initialAmount == 0) {
    return true
  } else {
    return false
  }
}

function enoughValue(value): boolean {
  if (value >= 1) {
    return true
  } else {
    return false
  }
}

export function deployTest(): boolean {
  if (walletSpecified() && enoughValue(100) && ownerDist(0)) {
    return true
  } else {
    return false
  }
  //assert.isTrue(walletSpecified() && enoughValue(100) && ownerDist(100))
}
