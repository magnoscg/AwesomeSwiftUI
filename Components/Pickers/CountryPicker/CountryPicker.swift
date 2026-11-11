// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct CountryPickerCountry: Identifiable, Hashable, Sendable {
    let code: String
    let name: String
    let dialCode: String

    var id: String { code }
    var flag: String { CountryPickerData.flag(for: code) }
}

/// A searchable list of countries with flags and dial codes. Use it inside a `NavigationStack`.
///
/// It opens on the selected country, or on the region of the device if there is none.
struct CountryPicker: View {
    @Binding var selection: String?
    var countries: [CountryPickerCountry] = CountryPickerData.all

    @State private var query = ""

    private var results: [CountryPickerCountry] {
        CountryPickerData.filter(countries, query: query)
    }

    var body: some View {
        ScrollViewReader { proxy in
            List(results) { country in
                row(for: country)
                    .id(country.code)
            }
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(text: $query, prompt: "Country or dial code")
            .task {
                if let start = selection ?? Locale.current.region?.identifier {
                    proxy.scrollTo(start, anchor: .center)
                }
            }
        }
    }

    private func row(for country: CountryPickerCountry) -> some View {
        Button {
            selection = country.code
        } label: {
            HStack(spacing: 12) {
                Text(country.flag)
                    .font(.title2)
                    .accessibilityHidden(true)

                // `Color.primary`, not `.primary`: inside a button the style is a shade of the tint.
                Text(country.name)
                    .foregroundStyle(Color.primary)

                Spacer(minLength: 8)

                Text(country.dialCode)
                    .foregroundStyle(Color.secondary)
                    .monospacedDigit()

                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
                    .opacity(selection == country.code ? 1 : 0)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityAddTraits(selection == country.code ? .isSelected : [])
    }
}

enum CountryPickerData {
    /// Every country in the table below that the system knows, named in the current language.
    static let all = countries(locale: .current)

    static func countries(locale: Locale) -> [CountryPickerCountry] {
        Locale.Region.isoRegions
            .compactMap { region -> CountryPickerCountry? in
                guard let dialCode = dialCodes[region.identifier] else { return nil }
                let name = locale.localizedString(forRegionCode: region.identifier) ?? region.identifier
                return CountryPickerCountry(code: region.identifier, name: name, dialCode: dialCode)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Matches names and region codes anywhere, and dial codes from their start.
    static func filter(_ countries: [CountryPickerCountry], query: String) -> [CountryPickerCountry] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return countries }

        let digits = text.hasPrefix("+") ? String(text.dropFirst()) : text
        return countries.filter { country in
            country.name.localizedStandardContains(text)
                || country.code.caseInsensitiveCompare(text) == .orderedSame
                || (!digits.isEmpty && country.dialCode.dropFirst().hasPrefix(digits))
        }
    }

    /// Two letters become the two regional indicator symbols that draw a flag.
    static func flag(for code: String) -> String {
        let letters = code.uppercased().unicodeScalars
        guard letters.count == 2, letters.allSatisfy({ ("A"..."Z").contains($0) }) else { return "" }
        var flag = String.UnicodeScalarView()
        flag.append(contentsOf: letters.compactMap { Unicode.Scalar(127_397 + $0.value) })
        return String(flag)
    }

    /// Parses entries such as `ES34` into `["ES": "+34"]`. Apple has no API for dial codes.
    static func parseDialCodes(_ table: String) -> [String: String] {
        let pairs = table.split(whereSeparator: \.isWhitespace).compactMap { entry -> (String, String)? in
            let digits = entry.dropFirst(2)
            guard entry.count > 2, digits.allSatisfy(\.isNumber) else { return nil }
            return (String(entry.prefix(2)), "+" + digits)
        }
        return Dictionary(pairs) { first, _ in first }
    }

    private static let dialCodes = parseDialCodes("""
        AD376 AE971 AF93 AG1268 AI1264 AL355 AM374 AO244 AR54 AS1684 AT43 AU61 AW297 AX358 AZ994
        BA387 BB1246 BD880 BE32 BF226 BG359 BH973 BI257 BJ229 BL590 BM1441 BN673 BO591 BQ599 BR55
        BS1242 BT975 BW267 BY375 BZ501 CA1 CC61 CD243 CF236 CG242 CH41 CI225 CK682 CL56 CM237 CN86
        CO57 CR506 CU53 CV238 CW599 CX61 CY357 CZ420 DE49 DJ253 DK45 DM1767 DO1809 DZ213 EC593 EE372
        EG20 EH212 ER291 ES34 ET251 FI358 FJ679 FK500 FM691 FO298 FR33 GA241 GB44 GD1473 GE995 GF594
        GG44 GH233 GI350 GL299 GM220 GN224 GP590 GQ240 GR30 GT502 GU1671 GW245 GY592 HK852 HN504 HR385
        HT509 HU36 ID62 IE353 IL972 IM44 IN91 IO246 IQ964 IR98 IS354 IT39 JE44 JM1876 JO962 JP81
        KE254 KG996 KH855 KI686 KM269 KN1869 KP850 KR82 KW965 KY1345 KZ7 LA856 LB961 LC1758 LI423
        LK94 LR231 LS266 LT370 LU352 LV371 LY218 MA212 MC377 MD373 ME382 MF590 MG261 MH692 MK389
        ML223 MM95 MN976 MO853 MP1670 MQ596 MR222 MS1664 MT356 MU230 MV960 MW265 MX52 MY60 MZ258
        NA264 NC687 NE227 NF672 NG234 NI505 NL31 NO47 NP977 NR674 NU683 NZ64 OM968 PA507 PE51 PF689
        PG675 PH63 PK92 PL48 PM508 PR1787 PS970 PT351 PW680 PY595 QA974 RE262 RO40 RS381 RU7 RW250
        SA966 SB677 SC248 SD249 SE46 SG65 SH290 SI386 SJ47 SK421 SL232 SM378 SN221 SO252 SR597 SS211
        ST239 SV503 SX1721 SY963 SZ268 TC1649 TD235 TG228 TH66 TJ992 TK690 TL670 TM993 TN216 TO676
        TR90 TT1868 TV688 TW886 TZ255 UA380 UG256 US1 UY598 UZ998 VA39 VC1784 VE58 VG1284 VI1340
        VN84 VU678 WF681 WS685 XK383 YE967 YT262 ZA27 ZM260 ZW263
        """)
}

// MARK: - Demo

struct CountryPickerDemo: View {
    @State private var selection = Locale.current.region?.identifier

    private var chosen: CountryPickerCountry? {
        CountryPickerData.all.first { $0.code == selection }
    }

    var body: some View {
        NavigationStack {
            CountryPicker(selection: $selection)
                .navigationTitle("Country")
                .safeAreaInset(edge: .bottom) {
                    if let chosen {
                        HStack(spacing: 10) {
                            Text(chosen.flag)
                                .font(.title)
                                .accessibilityHidden(true)

                            Text(chosen.name)
                                .font(.headline)

                            Spacer(minLength: 8)

                            Text(chosen.dialCode)
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial, in: .rect(cornerRadius: 20))
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .accessibilityElement(children: .combine)
                    }
                }
        }
    }
}

#Preview {
    CountryPickerDemo()
}
