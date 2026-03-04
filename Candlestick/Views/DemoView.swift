//
//  DemoView.swift
//  Candlestick
//
//  Created by Brandon Grossnickle on 2/11/25.
//

import SwiftUI

struct DemoView: View {
    @Environment(\.requestReview) var requestReview
    @Namespace private var zoomAnimation
    let chartAnalysis: ChartAnalysis?
    let image: UIImage?
    let date: Date?
    let onSurveyRequested: () -> Void

    @State private var showDemoRatingCard: Bool = false
    @State var selectedReaction: ReactionType? = nil

    @State private var imageScale: CGFloat = 1
    @State private var lastImageScale: CGFloat = 1
    @State private var imageOffset: CGSize = .zero
    @State private var lastImageOffset: CGSize = .zero
    
    @State var showArticles: Bool = false
    @State var showImageView: Bool = false

    // Collapsible section states
    @State private var showGeneralTrend = true
    @State private var showTradeSetup = true
    @State private var showSupportResistance = true
    @State private var showCandlestickPatterns = true
    @State private var showIndicators = true
    @State private var showFuturePrediction = true

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let analysis = chartAnalysis {
                        // Chart image
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .onTapGesture {
                                    withAnimation(.easeIn) {
                                        showImageView = true
                                    }
                                }
                        }
                        // Ticker + Date
                        VStack(alignment: .leading, spacing: 4) {
                            Text(analysis.ticker)
                                .font(Font.custom("Space Grotesk Bold", size: 32.0))
                                .foregroundColor(.white)
                            Text(formattedDate(date: date ?? Date()))
                                .font(Font.custom("Space Grotesk", size: 14.0))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        // Sections
                        SectionCard(title: "General Trend", icon: "chart.line.uptrend.xyaxis") {
                            GeneralTrendsView(analysis: analysis)
                        }
                        SectionCard(title: "Potential Trade Setup", icon: "sparkles") {
                            PotentialTradeSetupView(analysis: analysis)
                        }
                        SectionCard(title: "Support & Resistance", icon: "line.horizontal.3.decrease") {
                            SupportResistanceView(analysis: analysis)
                        }
                        SectionCard(title: "Candlestick Patterns", icon: "flame.fill") {
                            CandlestickPatternsView(analysis: analysis)
                        }
                        SectionCard(title: "Indicator Analyses", icon: "waveform.path.ecg") {
                            IndicatorAnalysesView(analysis: analysis)
                        }
                        SectionCard(title: "Future Market Prediction", icon: "clock.arrow.circlepath") {
                            FutureMarketPredictionsView(analysis: analysis)
                        }
                        HStack(spacing: 4) {
                            Text("Disclaimer: This is not financial advice. Always seek the advice of a licensed professional before investing.")
                                .font(.caption)
                                .italic()
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.top, 8)
                    } else {
                        Text("No analysis data available.")
                            .font(Font.custom("Space Grotesk", size: 16.0))
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
            .mask(LinearGradient(
                gradient: Gradient(colors: [
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    .black,
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.0),
                    .clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            ))
            VStack {
                Spacer()
                Button(action: {
                    AnalyticsManager.shared.logDemoViewComplete()
                    showDemoRatingCard = true
                }) {
                    HStack {
                        Spacer()
                        Text("Continue")
                            .foregroundStyle(Color.alphaBlack)
                            .font(Font.custom("Space Grotesk Bold", size: 20.0))
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                .padding()
                .buttonStyle(ScaleButtonStyle())
            }
            .navigationBarBackButtonHidden(true)
            Color.black.opacity(showDemoRatingCard ? 0.64 : 0).ignoresSafeArea()
                .onTapGesture {
                    showDemoRatingCard = false
                }
            DemoRatingCard(isVisible: $showDemoRatingCard, selectedReaction: $selectedReaction)
                .scaleEffect(showDemoRatingCard ? 1.0 : 0.0)
                .transition(.scale)
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: showDemoRatingCard)
                .padding()
        }
        .background(Color.alphaBlack.ignoresSafeArea())
        .overlay {
            ZStack {
                if showImageView {
                    ImageView()
                }
            }
        }
        .onChange(of: selectedReaction) {
            AnalyticsManager.shared.logDemoReaction(reaction: selectedReaction?.label ?? "None")
            if selectedReaction == .impressive || selectedReaction == .needThis || selectedReaction == .prettyCool {
                requestReview()
            }
              
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onSurveyRequested()
            }
        }

    }
    
    @ViewBuilder
    func ImageView() -> some View {
        ZStack(alignment: .topLeading) {
            Color.alphaBlack.ignoresSafeArea()
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(imageScale)
                    .offset(imageOffset) // Apply drag offset
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    withAnimation {
                                        imageScale = max(0.5, value * lastImageScale)
                                    }
                                }
                                .onEnded { _ in
                                    if imageScale < 1 {
                                        withAnimation {
                                            imageScale = 1
                                        }
                                    }
                                    else {
                                        lastImageScale = imageScale
                                    }
                                },
                            DragGesture()
                                .onChanged { value in
                                    guard imageScale > 1 else { return }
                                    withAnimation {
                                        imageOffset = CGSize(
                                            width: lastImageOffset.width + value.translation.width,
                                            height: lastImageOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastImageOffset = imageOffset
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if imageScale == 1 {
                                imageScale = 4
                            } else {
                                imageScale = 1
                                imageOffset = .zero
                                lastImageOffset = .zero
                            }
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        Button(action: {
                            withAnimation(.easeOut) {
                                showImageView = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .padding()
                                .background(Color.black)
                                .clipShape(Circle())
                                .foregroundStyle(Color.white)
                                .bold()
                        }
                        .padding()
                    }
            }
        }
    }
    
    @ViewBuilder
    func GeneralTrendsView(analysis: ChartAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .center, spacing: 16) {
                HStack {
                    HStack(spacing: 12) {
                       Image(systemName: getTrendImage(analysis: analysis))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(getTrendColor(analysis: analysis))
                            .bold()
                            .padding(10.0)
                            .background(Color.alphaBlack)
                            .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
                        VStack(alignment: .leading) {
                            Text("Trend")
                                .font(Font.custom("Space Grotesk", size: 14.0))
                                .foregroundStyle(Color.white)
                            Text(displayTrendDirection(analysis.features.generalTrends.trendDirection))
                                .font(Font.custom("Space Grotesk Bold", size: 16.0))
                                .foregroundStyle(Color.white)
                        }
                        Spacer()
                    }
                    HStack(spacing: 12) {
                        Image(systemName: getSignalImage(analysis: analysis))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(getSignalColor(analysis: analysis))
                            .bold()
                            .padding(10.0)
                            .background(Color.alphaBlack)
                            .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
                        VStack(alignment: .leading) {
                            Text("Signal")
                                .font(Font.custom("Space Grotesk", size: 14.0))
                                .foregroundStyle(Color.white)
                            Text(getSignalLabel(analysis: analysis))
                                .font(Font.custom("Space Grotesk Bold", size: 16.0))
                                .foregroundStyle(getSignalColor(analysis: analysis))
                        }
                        Spacer()
                    }
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Volume")
                            .font(Font.custom("Space Grotesk", size: 14.0))
                            .foregroundStyle(Color.white)
                            .padding(.leading, 4.0)
                        HStack {
                            VStack(alignment: .leading) {
                                Text(analysis.features.generalTrends.volume.capitalized)
                                    .font(Font.custom("Space Grotesk Bold", size: 16.0))
                                    .foregroundStyle(Color.white)
                                ZStack(alignment: .leading) {
                                    getVolumeColor(analysis: analysis).opacity(0.32).frame(width: 100, height: 8)
                                    getVolumeColor(analysis: analysis).frame(width: 100 * getVolumeStrength(analysis: analysis), height: 8)
                                }
                                .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.alphaBlack)
                        .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
//                        .shadow(color: Color.candlestickBackground, radius: 10, x: 5, y: 5)
                        
                    }
                    Spacer()
                    HStack {
                        
                    }
                    VStack(alignment: .leading) {
                        Text("Volatility")
                            .font(Font.custom("Space Grotesk", size: 14.0))
                            .padding(.leading, 4.0)
                            .foregroundStyle(Color.white)
                        HStack {
                            VStack(alignment: .leading) {
                                Text(analysis.features.generalTrends.volatility.capitalized)
                                    .font(Font.custom("Space Grotesk Bold", size: 16.0))
                                    .foregroundStyle(Color.white)
                                ZStack(alignment: .leading) {
                                    getVolatilityColor(analysis: analysis).opacity(0.32).frame(width: 100, height: 8)
                                    getVolatilityColor(analysis: analysis).frame(width: 100 * getVolatilityStrength(analysis: analysis), height: 8)
                                }
                                .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.alphaBlack)
                        .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
//                        .shadow(color: Color.candlestickBackground, radius: 10, x: 5, y: 5)
                        
                    }
                    Spacer()
                }
            }
            Divider()
            CollapsibleAnalysis(text: analysis.features.generalTrends.analysis, isExpanded: $showGeneralTrend)
        }
    }

    func displayTrendDirection(_ direction: String) -> String {
        switch direction.lowercased() {
        case "up": return "Bullish"
        case "down": return "Bearish"
        case "sideways": return "Neutral"
        default: return direction.capitalized
        }
    }

    func getTrendImage(analysis: ChartAnalysis) -> String {
        if analysis.features.generalTrends.trendDirection == "up" {
          return "chart.line.uptrend.xyaxis"
        }
        else if analysis.features.generalTrends.trendDirection == "down" {
            return "chart.line.downtrend.xyaxis"
        }
        else if analysis.features.generalTrends.trendDirection == "sideways" {
            return "chart.line.flattrend.xyaxis"
        }
        else {
           return "exclamationmark.circle.fill"
        }
    }
    
    func getTrendColor(analysis: ChartAnalysis) -> Color {
        if analysis.features.generalTrends.trendDirection == "up" {
            return Color.alphaGreen
        }
        else if analysis.features.generalTrends.trendDirection == "down" {
            return Color.red
        }
        else if analysis.features.generalTrends.trendDirection == "sideways" {
            return Color.black
        }
        else {
            return Color.red
        }
    }
    
    func getSignalLabel(analysis: ChartAnalysis) -> String {
        switch analysis.features.potentialTradeSetup.tradeDirection?.lowercased() {
        case "long": return "Buy"
        case "short": return "Sell"
        default: return "Hold"
        }
    }

    func getSignalImage(analysis: ChartAnalysis) -> String {
        switch analysis.features.potentialTradeSetup.tradeDirection?.lowercased() {
        case "long": return "arrow.up.circle.fill"
        case "short": return "arrow.down.circle.fill"
        default: return "pause.circle.fill"
        }
    }

    func getSignalColor(analysis: ChartAnalysis) -> Color {
        switch analysis.features.potentialTradeSetup.tradeDirection?.lowercased() {
        case "long": return Color.alphaGreen
        case "short": return Color.red
        default: return Color.white
        }
    }
    
    func getVolumeColor(analysis: ChartAnalysis) -> Color {
        if analysis.features.generalTrends.volume == "low" {
            return Color.teal
        }
        else if analysis.features.generalTrends.volume == "medium" {
            return Color.white
        }
        else if analysis.features.generalTrends.volume == "high" {
            return Color.purple
        }
        else {
            return Color.white
        }
    }
    
    func getVolumeStrength(analysis: ChartAnalysis) -> Double {
        if analysis.features.generalTrends.volume == "low" {
            return 0.33
        }
        else if analysis.features.generalTrends.volume == "medium" {
            return 0.50
        }
        else if analysis.features.generalTrends.volume == "high" {
            return 0.80
        }
        else {
            return 0.0
        }
    }
    
    func getVolatilityColor(analysis: ChartAnalysis) -> Color {
        if analysis.features.generalTrends.volatility == "low" {
            return Color.cyan
        }
        else if analysis.features.generalTrends.volatility == "medium" {
            return Color.white
        }
        else if analysis.features.generalTrends.volatility == "high" {
            return Color.pink
        }
        else {
            return Color.white
        }
    }
    
    func getVolatilityStrength(analysis: ChartAnalysis) -> Double {
        if analysis.features.generalTrends.volatility == "low" {
            return 0.33
        }
        else if analysis.features.generalTrends.volatility == "medium" {
            return 0.50
        }
        else if analysis.features.generalTrends.volatility == "high" {
            return 0.80
        }
        else {
            return 0.0
        }
    }
    
    @ViewBuilder
    func SupportResistanceView(analysis: ChartAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack {
                    HStack(spacing: 12) {
                       Image(systemName: "arrow.down.to.line")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.alphaGreen)
                            .bold()
                            .padding(10.0)
                            .background(Color.alphaBlack)
                            .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
//                            .shadow(color: Color.candlestickBackground, radius: 10, x: 5, y: 5)
                        VStack(alignment: .leading) {
                            Text("Support")
                                .font(Font.custom("Space Grotesk", size: 14.0))
                                .foregroundStyle(Color.white)
                            ForEach(analysis.features.supportResistance.supportLevels, id:\.self) { supportLevel in
                                Text("$\(supportLevel)")
                                    .font(Font.custom("Space Grotesk Bold", size: 16.0))
                                    .foregroundStyle(Color.white)
                            }
                        }
                    }
                    Spacer()
                    HStack(spacing: 12) {
                       Image(systemName: "arrow.up.to.line")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.red)
                            .bold()
                            .padding(10.0)
                            .background(Color.alphaBlack)
                            .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
//                            .shadow(color: Color.candlestickBackground, radius: 10, x: 5, y: 5)
                        VStack(alignment: .leading) {
                            Text("Resistance")
                                .font(Font.custom("Space Grotesk", size: 14.0))
                                .foregroundStyle(Color.white)
                            ForEach(analysis.features.supportResistance.resistanceLevels, id:\.self) { resistanceLevel in
                                Text("$\(resistanceLevel)")
                                    .font(Font.custom("Space Grotesk Bold", size: 16.0))
                                    .foregroundStyle(Color.white)
                            }
                        }
                    }
                    Spacer()
                }
            }
            Divider()
            CollapsibleAnalysis(text: analysis.features.supportResistance.analysis, isExpanded: $showSupportResistance)
        }
    }

    @ViewBuilder
    func CandlestickPatternsView(analysis: ChartAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if analysis.features.candlestickPatterns.recognizedPatterns.isEmpty {
                Text("No candlestick patterns were recognized in this analysis.")
                    .font(Font.custom("Space Grotesk", size: 14.0))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(Color.white)
            }
            else {
                ForEach(analysis.features.candlestickPatterns.recognizedPatterns, id: \.patternName) { recognizedPattern in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recognizedPattern.patternName)
                            .font(Font.custom("Space Grotesk Bold", size: 16.0))
                            .foregroundStyle(Color.white)
                        Text(recognizedPattern.analysis)
                            .font(Font.custom("Space Grotesk", size: 14.0))
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(Color.white)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func IndicatorAnalysesView(analysis: ChartAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(analysis.features.indicatorAnalyses.selectedIndicators, id: \.indicatorName) { selectedIndicator in
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedIndicator.indicatorName)
                        .font(Font.custom("Space Grotesk Bold", size: 16.0))
                        .foregroundStyle(Color.white)
                    Text(selectedIndicator.analysis)
                        .font(Font.custom("Space Grotesk", size: 14.0))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
    
    @ViewBuilder
    func FutureMarketPredictionsView(analysis: ChartAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack {
                    HStack(spacing: 12) {
                       Image(systemName: "sun.horizon.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.orange)
                            .bold()
                            .padding(10.0)
                            .background(Color.alphaBlack)
                            .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
//                            .shadow(color: Color.candlestickBackground, radius: 10, x: 5, y: 5)
                        VStack(alignment: .leading) {
                            Text("Horizon")
                                .font(Font.custom("Space Grotesk", size: 14.0))
                                .foregroundStyle(Color.white)
                            Text(getHorizonLabel(analysis: analysis))
                                .font(Font.custom("Space Grotesk Bold", size: 16.0))
                                .foregroundStyle(Color.white)
                        }
                    }
                    Spacer()
                }
            }
            Divider()
            CollapsibleAnalysis(text: analysis.features.futureMarketPrediction.analysis, isExpanded: $showFuturePrediction)
        }
    }

    func getHorizonLabel(analysis: ChartAnalysis) -> String {
        if analysis.features.futureMarketPrediction.timeHorizon == "short_term" {
           return "Short Term"
        }
        else if analysis.features.futureMarketPrediction.timeHorizon == "medium_term" {
            return "Medium Term"
        }
        else if analysis.features.futureMarketPrediction.timeHorizon == "long_term" {
            return "Long Term"
        }
        else {
            return "Error"
        }
    }
    
    @ViewBuilder
    func PotentialTradeSetupView(analysis: ChartAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label {
                        Text(analysis.features.potentialTradeSetup.tradeDirection?.capitalized ?? "N/A")
                            .font(Font.custom("Space Grotesk Bold", size: 16))
                            .foregroundStyle(
                                (analysis.features.potentialTradeSetup.tradeDirection ?? "").lowercased() == "long"
                                ? Color.alphaGreen
                                : Color.red
                            )
                    } icon: {
                        Image(systemName: (analysis.features.potentialTradeSetup.tradeDirection ?? "").lowercased() == "long"
                              ? "arrow.up.circle.fill"
                              : "arrow.down.circle.fill")
                            .foregroundStyle(
                                (analysis.features.potentialTradeSetup.tradeDirection ?? "").lowercased() == "long"
                                ? Color.alphaGreen
                                : Color.red
                            )
                    }
                    .font(.headline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.alphaBlack)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Spacer()
                }

                HStack(spacing: 24) {
                    HStack(spacing: 12) {
                        Image(systemName: "scope")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.alphaGreen)
                            .padding(10)
                            .background(Color.alphaBlack)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Entry")
                                .font(Font.custom("Space Grotesk", size: 14))
                                .foregroundStyle(.white)
                            Text("$\(analysis.features.potentialTradeSetup.entryTargetPrice)")
                                .font(Font.custom("Space Grotesk Bold", size: 16))
                                .foregroundStyle(Color.alphaGreen)
                        }
                        Spacer()
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.red)
                            .padding(10)
                            .background(Color.alphaBlack)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Stop Loss")
                                .font(Font.custom("Space Grotesk", size: 14))
                                .foregroundStyle(.white)
                            Text("$\(analysis.features.potentialTradeSetup.stopLossPrice)")
                                .font(Font.custom("Space Grotesk Bold", size: 16))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                }

                // --- Target Prices ---
                if let targets = analysis.features.potentialTradeSetup.targetPrices, !targets.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "target")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.yellow)
                            .padding(10)
                            .background(Color.alphaBlack)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(targets.count == 1 ? "Target" : "Targets")
                                .font(Font.custom("Space Grotesk", size: 14))
                                .foregroundStyle(.white)
                            HStack(spacing: 8) {
                                ForEach(targets, id: \.self) { t in
                                    Text("$\(t)")
                                        .font(Font.custom("Space Grotesk Bold", size: 16))
                                        .foregroundStyle(Color.yellow)
                                }
                            }
                        }
                        Spacer()
                    }
                }
            }
            Divider()
            CollapsibleAnalysis(text: analysis.features.potentialTradeSetup.analysis, isExpanded: $showTradeSetup)
        }
    }

    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
