import SwiftUI
import UIKit

struct DebugOverlayRoot: View {
    @Bindable var model: DebugModel
    let onSave: (String) -> Void

    @AppStorage("debug.button.trailing") private var onTrailing = true
    @AppStorage("debug.button.yRatio") private var yRatio = 0.75
    @State private var dragOffset: CGSize = .zero
    @State private var isNaming = false
    @State private var snapshotLabel = ""
    @State private var copied = false

    private let buttonSize: CGFloat = 52
    private let edgeInset: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if model.isOpen {
                    panel(in: geo.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity,
                               alignment: model.anchor == .bottom ? .bottom : .top)
                        .padding(.horizontal, 8)
                        .transition(.move(edge: model.anchor == .bottom ? .bottom : .top).combined(with: .opacity))
                }
                button
                    .position(buttonCenter(in: geo.size))
                    .gesture(dragGesture(in: geo.size))
            }
            .animation(.snappy, value: model.isOpen)
            .animation(.snappy, value: model.anchor)
        }
        .alert("스냅샷 저장", isPresented: $isNaming) {
            TextField("라벨 (예: Duo 펼침 가로)", text: $snapshotLabel)
            Button("저장") { onSave(snapshotLabel) }
            Button("취소", role: .cancel) {}
        } message: {
            Text("현재 값을 '실측 기록'에 저장합니다.")
        }
    }

    // MARK: - 플로팅 버튼

    private var button: some View {
        VStack(spacing: 1) {
            Image(systemName: model.isOpen ? "xmark" : "ruler")
                .font(.system(size: 16, weight: .semibold))
            Text(model.snapshot.badge)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(.white)
        .frame(width: buttonSize, height: buttonSize)
        .background(Circle().fill(Color.indigo.gradient))
        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
        .contentShape(Circle())
        .onTapGesture {
            if !model.isOpen { model.anchor = yRatio > 0.5 ? .top : .bottom }
            model.isOpen.toggle()
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { model.buttonFrame = $0 }
        .accessibilityLabel("레이아웃 디버그 패널")
        .accessibilityAddTraits(.isButton)
    }

    private func restingCenter(in size: CGSize) -> CGPoint {
        let r = buttonSize / 2 + edgeInset
        let x = onTrailing ? size.width - r : r
        let y = min(max(yRatio * size.height, r), size.height - r)
        return CGPoint(x: x, y: y)
    }

    private func buttonCenter(in size: CGSize) -> CGPoint {
        let base = restingCenter(in: size)
        return CGPoint(x: base.x + dragOffset.width, y: base.y + dragOffset.height)
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { dragOffset = $0.translation }
            .onEnded { value in
                let base = restingCenter(in: size)
                let end = CGPoint(x: base.x + value.translation.width, y: base.y + value.translation.height)
                withAnimation(.snappy) {
                    onTrailing = end.x > size.width / 2
                    yRatio = size.height > 0 ? min(max(end.y / size.height, 0), 1) : 0.75
                    dragOffset = .zero
                }
            }
    }

    // MARK: - 패널

    private func panel(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            header
            Divider()
            switch model.tab {
            case .metrics: metricsList
            case .log: logList
            }
        }
        .frame(width: min(size.width - 16, 460), height: min(size.height * 0.72, 600))
        .background(.ultraThickMaterial, in: .rect(cornerRadius: 20))
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.15)))
        .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { model.panelFrame = $0 }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Picker("탭", selection: $model.tab) {
                ForEach(DebugModel.Tab.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 200)

            Spacer(minLength: 0)

            Button {
                UIPasteboard.general.string = model.snapshot.plainText
                copied = true
                Task { try? await Task.sleep(for: .seconds(1.2)); copied = false }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
            }
            .accessibilityLabel("텍스트 복사")

            Button {
                snapshotLabel = "\(model.snapshot.key.shape) \(model.snapshot.key.size)"
                isNaming = true
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .accessibilityLabel("스냅샷 저장")

            Button {
                model.anchor = model.anchor == .bottom ? .top : .bottom
            } label: {
                Image(systemName: model.anchor == .bottom ? "arrow.up.to.line" : "arrow.down.to.line")
            }
            .accessibilityLabel("패널 위치 바꾸기")
        }
        .font(.body.weight(.medium))
        .padding(12)
    }

    private var metricsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(model.snapshot.sections) { section in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.indigo)
                        ForEach(section.rows) { row in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(row.key)
                                    .foregroundStyle(Color.gray)
                                    .lineLimit(2)
                                    .layoutPriority(1)
                                Spacer(minLength: 8)
                                Text(row.value)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(row.warn ? Color.orange : Color.primary)
                            }
                            .font(.system(size: 11, design: .monospaced))
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    private var logList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(model.log.count)개 · 최근 100개 유지").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("비우기") { model.log.removeAll() }.font(.caption)
                }
                ForEach(model.log) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.date, format: .dateTime.hour().minute().second().secondFraction(.fractional(2)))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.indigo)
                        ForEach(entry.changes, id: \.self) { line in
                            Text(line).font(.system(size: 11, design: .monospaced))
                        }
                    }
                }
            }
            .padding(12)
        }
    }
}
