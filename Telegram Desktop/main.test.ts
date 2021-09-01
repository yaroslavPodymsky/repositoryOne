import { callThroughMultisig } from '@ton-contracts/utils/net';
import { utf8ToHex } from '@ton-contracts/utils/convert';
import { TonClient } from "@tonclient/core";
import { createClient } from "@ton-contracts/utils/client";
import TonContract from "@ton-contracts/utils/ton-contract";
import pkgSafeMultisigWallet from "../ton-packages/SafeMultisigWallet.package";
import pkgEvent from "../ton-packages/Event.package";
import pkgIndex from "../ton-packages/Index.package";
import pkgTicket from "../ton-packages/Ticket.package";
import { expect } from 'chai';
const fs = require("fs");

describe("debot test", () => {
  let client: TonClient;
  let smcSafeMultisigWallet: TonContract;
  let smcEvent: TonContract;
  let smcTicket: TonContract;
  let keys: any;
  let addrTicket: string;
  let randomString = () => {
    let abc = "abcdefghijklmnopqrstuvwxyz";
    let rs = "";
    while (rs.length < 6) {
      rs += abc[Math.floor(Math.random() * abc.length)];
    }
    return rs
  }

  before(async () => {
    client = createClient();
    smcSafeMultisigWallet = new TonContract({
      client,
      name: "SafeMultisigWallet",
      tonPackage: pkgSafeMultisigWallet,
      address: process.env.MULTISIG_ADDRESS,
      keys: {
        public: process.env.MULTISIG_PUBKEY,
        secret: process.env.MULTISIG_SECRET,
      },
    });

    keys = await client.crypto.generate_random_sign_keys();


  });

  it("deploy event", async () => {
    let eventName = utf8ToHex(randomString())
    smcEvent = new TonContract({
      client,
      name: "Event",
      tonPackage: pkgEvent,
      keys
    });

    await smcEvent.calcAddress({
      initialData: {
        _owner: smcSafeMultisigWallet.address,
        _name: eventName
      }
    })

    console.log('Event address: ', smcEvent.address)


    await smcSafeMultisigWallet.call({
      functionName: "sendTransaction",
      input: {
        dest: smcEvent.address,
        value: 2e9,
        bounce: false,
        flags: 2,
        payload: "",
      },
    });

    await smcEvent.deploy({
      input: {
        place: {
          name: utf8ToHex("Place name"),
          coordinates: [utf8ToHex('12341234'), utf8ToHex('12341234')],
          postal: utf8ToHex('Event postal address')
        },
        addrsGatekeeper: [smcSafeMultisigWallet.address],
        ticketKinds: [
          {
            id: utf8ToHex('vip'),
            total: 100,
            available: 100,
            price: 1e9
          }
        ],
        checkpoints: {
          start: 1627478362,
          end: 1627478362,
          control: 1627478362
        },
        codeTicket: (
          await client.boc.get_code_from_tvc({ tvc: pkgTicket.image })
        ).code,
        codeIndex: (
          await client.boc.get_code_from_tvc({ tvc: pkgIndex.image })
        ).code,
        addrStore: smcEvent.address
      },
      initialData: {
        _owner: smcSafeMultisigWallet.address,
        _name: eventName
      }
    })

  });

  it("add gatekeper", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgEvent.abi,
      functionName: "addGatekeeper",
      input: {
        addrGatekeeper: smcSafeMultisigWallet.address
      },
      dest: smcEvent.address,
      value: 1e9,
    });

    const res = await smcEvent.run({
      functionName: 'getAll'
    })
    expect(res.value.eventData.addrsGatekeeper.length).to.be.equal(2)
  })

  it("remove gatekeper", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgEvent.abi,
      functionName: "removeGatekeeper",
      input: {
        addrGatekeeper: smcSafeMultisigWallet.address,
        index: 0
      },
      dest: smcEvent.address,
      value: 1e9,
    });

    const res = await smcEvent.run({
      functionName: 'getAll'
    })
    expect(res.value.eventData.addrsGatekeeper.length).to.be.equal(1)
  })

  it("add ticket kind", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgEvent.abi,
      functionName: "addTicketKind",
      input: {
        ticketKind: {
          id: utf8ToHex('common'),
          total: 100,
          available: 100,
          price: 1e9
        }
      },
      dest: smcEvent.address,
      value: 1e9,
    });

    const res = await smcEvent.run({
      functionName: 'getAll'
    })
    expect(res.value.eventData.ticketKinds.length).to.be.equal(2)
  })

  it("mint ticket", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgEvent.abi,
      functionName: "mintNft",
      input: {
        indexTicketKind: 0
      },
      dest: smcEvent.address,
      value: 3e9,
    });

    const addr = await smcEvent.run({
      functionName: "calcAddrTicket",
      input: {
        id: 0
      }
    })

    addrTicket = addr.value.addrTicket

    smcTicket = new TonContract({
      client,
      name: "Ticket",
      tonPackage: pkgTicket,
      address: addrTicket,
      keys
    });

    const indexTicketKind = await smcTicket.run({
      functionName: "getInfo",
    })

    expect(indexTicketKind.value.indexTicketKind).to.be
      .equal('0x0000000000000000000000000000000000000000000000000000000000000000')
  })

  it("check ticket on sale FALSE", async () => {
    const isOnSale = await smcEvent.run({
      functionName: "checkTicketOnSale",
      input: {
        addrTicket: addrTicket
      }
    })

    expect(isOnSale.value.value0).to.be.equal(false)
  })

  it("put up ticket", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgTicket.abi,
      functionName: "putUpTicket",
      input: {
        price: 2e9
      },
      dest: smcTicket.address,
      value: 2e9,
    });
  })

  it("check ticket on sale TRUE", async () => {
    const isOnSale = await smcEvent.run({
      functionName: "checkTicketOnSale",
      input: {
        addrTicket: addrTicket
      }
    })

    expect(isOnSale.value.value0).to.be.equal(true)
  })

  it("withdraw ticket", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgTicket.abi,
      functionName: "withdrawTicket",
      input: {
        price: 1e9
      },
      dest: smcTicket.address,
      value: 2e9,
    });
  })

  it("check ticket on sale FALSE", async () => {
    const isOnSale = await smcEvent.run({
      functionName: "checkTicketOnSale",
      input: {
        addrTicket: addrTicket
      }
    })

    expect(isOnSale.value.value0).to.be.equal(false)
  })

  it("ready to enter", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgTicket.abi,
      functionName: "readyEnterToggle",
      input: {
        price: 1e9
      },
      dest: smcTicket.address,
      value: 2e9,
    });

    const res = await smcTicket.run({
      functionName: "getTicketStatus"
    })

    expect(res.value.ticketStatusInfo.isReady).to.be.equal(true)
  })

  it("register entry", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgEvent.abi,
      functionName: "setTicketStatus",
      input: {
        ticketStatus: 1,
        addrTicket: addrTicket,
        id: 0,
        indexGatekeeper: 0
      },
      dest: smcEvent.address,
      value: 1e9,
    });

    const res = await smcTicket.run({
      functionName: "getTicketStatus"
    })

    expect(res.value.ticketStatusInfo.status).to.be.equal('1')
  })

  it("register exit", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgEvent.abi,
      functionName: "setTicketStatus",
      input: {
        ticketStatus: 2,
        addrTicket: addrTicket,
        id: 0,
        indexGatekeeper: 0
      },
      dest: smcEvent.address,
      value: 1e9,
    });

    const res = await smcTicket.run({
      functionName: "getTicketStatus"
    })

    expect(res.value.ticketStatusInfo.status).to.be.equal('2')
  })
})

