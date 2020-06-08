//
//  Section104Holding.swift
//  cgtcalc
//
//  Created by Matt Galloway on 08/06/2020.
//

import Foundation

class Section104Holding {
  private(set) var state: State = State(amount: Decimal.zero, cost: 0.0)
  private let logger: Logger

  struct State {
    private(set) var amount: Decimal
    private(set) var cost: Decimal
    var costBasis: Decimal {
      if amount.isZero {
        return 0
      }
      return cost / amount
    }

    mutating func add(amount: Decimal, cost: Decimal) {
      self.amount += amount
      self.cost += cost
    }

    mutating func remove(amount: Decimal) {
      let costBasis = self.costBasis
      self.amount -= amount
      self.cost -= amount * costBasis
      if self.amount.isZero {
        self.cost = 0
      }
    }
  }

  init(logger: Logger) {
    self.logger = logger
  }

  func process(acquisition: SubTransaction) {
    self.logger.debug("Section 104 +++: \(acquisition)")
    self.state.add(amount: acquisition.amount, cost: acquisition.price * acquisition.amount + acquisition.expenses)
    self.logger.debug("  New state: \(self.state)")
  }

  func process(disposal: SubTransaction) throws -> DisposalMatch {
    self.logger.debug("Section 104 ---: \(disposal)")

    guard self.state.amount >= disposal.amount else {
      throw CalculatorError.InvalidData("Disposing of more than is currently held")
    }

    let disposalMatch = DisposalMatch(kind: .Section104(self.state.amount, self.state.costBasis), disposal: disposal)

    self.state.remove(amount: disposal.amount)
    self.logger.debug("  New state: \(self.state)")

    return disposalMatch
  }
}

extension Section104Holding.State: CustomStringConvertible {
  var description: String {
    return "<\(String(describing: type(of: self))): amount=\(self.amount), cost=\(self.cost), costBasis=\(self.costBasis)>"
  }
}
