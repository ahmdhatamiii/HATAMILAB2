import Foundation

struct AppConfig {
    /// Masukkan URL Deployment Google Apps Script Web App Anda (akhiran /exec) di sini:
    static let webAppUrl: String = "https://script.google.com/macros/s/AKfycbyI_ablMpaA2h_3u_TturAjc7mdPk5AQ0Lr0nXEzSW0dENpAAw5S8nUhM-vTYOWXOpD/exec"
    
    /// Judul Aplikasi
    static let appTitle: String = "Line Walker PLN UPT Semarang"
    
    /// Fitur Tarik untuk Refresh (Pull to Refresh)
    static let enablePullToRefresh: Bool = true
    
    /// Navigasi Geser Layar (Swipe to Go Back / Forward)
    static let enableSwipeGestures: Bool = true
}
