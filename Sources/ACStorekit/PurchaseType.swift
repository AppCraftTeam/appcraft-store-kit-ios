import Foundation

public enum PurchaseType: String, CaseIterable {
    case assistantChatMonthlyLight = "appcraft.demo.subscription.premium.month"
    case assistantChatMonthlyMedium = "appcraft.demo.subscription.premium.year"
    case assistantChatMonthlyHard = "ACMH"
    
    public var sortHeight: Int {
        switch self {
        case .assistantChatMonthlyLight:
            return 0
        case .assistantChatMonthlyMedium:
            return 1
        case .assistantChatMonthlyHard:
            return 2
        }
    }
    
    public var productIdentifer: String {
        self.rawValue
    }

    public var name: String {
        switch self {
        case .assistantChatMonthlyLight:
            return "Тариф Консультант"
        case .assistantChatMonthlyMedium:
            return "Тариф Комфорт"
        case .assistantChatMonthlyHard:
            return "Тариф Консьерж"
        }
    }
    
    public var info: String {
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
