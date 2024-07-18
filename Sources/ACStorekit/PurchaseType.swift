import Foundation

enum PurchaseType: String, CaseIterable {
    case assistantChatMonthlyLight = "ACML"
    case assistantChatMonthlyMedium = "ACMM"
    case assistantChatMonthlyHard = "ACMH"
    
    var sortHeight: Int {
        switch self {
        case .assistantChatMonthlyLight:
            return 0
        case .assistantChatMonthlyMedium:
            return 1
        case .assistantChatMonthlyHard:
            return 2
        }
    }
    
    var productIdentifer: String {
        self.rawValue
    }

    var name: String {
        switch self {
        case .assistantChatMonthlyLight:
            return "Тариф Консультант"
        case .assistantChatMonthlyMedium:
            return "Тариф Комфорт"
        case .assistantChatMonthlyHard:
            return "Тариф Консьерж"
        }
    }
    
    var info: String {
        switch self {
        case .assistantChatMonthlyLight:
            return "Подробно проконсультируем по любой ситуации 24/7"
        case .assistantChatMonthlyMedium:
            return "Дополнительно: оптимизация расходов, помощь в ремонте и обслуживании 🔧"
        case .assistantChatMonthlyHard:
            return "Дополнительно: помощь с документами, запись на техосмотр, любые вопросы 🤵‍♂️"
        }
    }

}
