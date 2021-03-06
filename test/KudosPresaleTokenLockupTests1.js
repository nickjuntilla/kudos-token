const BigNumber = web3.BigNumber

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()


import latestTime from './helpers/latestTime'
import {increaseTimeTo, duration} from './helpers/increaseTime'

const KudosToken = artifacts.require('KudosToken')
const KudosPresaleTokenLockup = artifacts.require('KudosPresaleTokenLockup')

contract('KudosPresaleTokenLockupTests1', function ([_, owner, beneficiary]) {

  const amount = new BigNumber(100)

  beforeEach(async function () {
    this.token = await KudosToken.new({from: owner})
    this.releaseTime = 1510754400
    this.timelock = await KudosPresaleTokenLockup.new(this.token.address, beneficiary)
    await this.token.transfer(this.timelock.address, amount, {from: owner})
  })

  it('fundsAreAvailable should return false before the time limit', async function () {
     const result = await this.timelock.fundsAreAvailable()
     result.should.equal(false)
  })

  it('cannot be released before time limit', async function () {
    await this.timelock.release().should.be.rejected
  })

  it('cannot be released just before time limit', async function () {
    await increaseTimeTo(this.releaseTime - duration.seconds(3))
    await this.timelock.release().should.be.rejected
  })

  it('can be released just after limit', async function () {
    await increaseTimeTo(this.releaseTime + duration.seconds(1))
    await this.timelock.release().should.be.fulfilled
    const balance = await this.token.balanceOf(beneficiary)
    balance.should.be.bignumber.equal(amount)
  })

  it('fundsAreAvailable should return true after the time limit', async function () {
     await increaseTimeTo(this.releaseTime + duration.seconds(1))
     const result = await this.timelock.fundsAreAvailable()
     result.should.equal(true)
  })

  it('can be released after time limit', async function () {
    await increaseTimeTo(this.releaseTime + duration.years(1))
    await this.timelock.release().should.be.fulfilled
    const balance = await this.token.balanceOf(beneficiary)
    balance.should.be.bignumber.equal(amount)
  })

  it('cannot be released twice', async function () {
    await increaseTimeTo(this.releaseTime + duration.years(1))
    await this.timelock.release().should.be.fulfilled
    await this.timelock.release().should.be.rejected
    const balance = await this.token.balanceOf(beneficiary)
    balance.should.be.bignumber.equal(amount)
  })
})
