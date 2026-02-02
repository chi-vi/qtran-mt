# **Báo cáo Nghiên cứu Chuyên sâu: Xây dựng Hệ thống Quy tắc Cú pháp cho Máy dịch Trung-Việt**

## **1. Tổng quan về Kiến trúc Ngữ pháp và Thách thức trong Dịch máy Trung-Việt**

### **1.1. Bản chất Loại hình học và Sự tương đồng giả kiến**

Trong lĩnh vực Xử lý Ngôn ngữ Tự nhiên (NLP), việc xây dựng một hệ thống dịch máy dựa trên quy tắc (Rule-based Machine Translation - RBMT) hoặc hệ thống lai (Hybrid) giữa tiếng Trung và tiếng Việt đòi hỏi sự thấu hiểu sâu sắc về bản chất loại hình học của hai ngôn ngữ này. Cả tiếng Trung và tiếng Việt đều thuộc loại hình ngôn ngữ đơn lập (isolating languages), đặc trưng bởi sự thiếu vắng hình thái biến đổi từ (không có chia động từ, biến cách danh từ) và sự phụ thuộc tuyệt đối vào trật tự từ (word order) cùng hư từ (function words) để biểu thị ý nghĩa ngữ pháp.1
Thoạt nhìn, cả hai ngôn ngữ đều chia sẻ trật tự câu cơ bản là S-V-O (Chủ ngữ - Động từ - Tân ngữ). Tuy nhiên, đối với một kỹ sư phát triển máy dịch, sự tương đồng này là "giả kiến" (deceptive). Sự khác biệt cốt lõi nằm ở **Cấu trúc ngữ đoạn (Phrase Structure)**, đặc biệt là sự đối lập về hướng của trung tâm ngữ (Head-directionality). Tiếng Trung có xu hướng đặt định ngữ trước trung tâm ngữ (Head-final in NP), trong khi tiếng Việt đặt định ngữ sau trung tâm ngữ (Head-initial in NP). Sự đảo ngược này chiếm tỷ trọng lớn nhất trong các thuật toán chuyển đổi cây cú pháp (Tree-to-Tree transformation).2
Báo cáo này sẽ phân tích chi tiết từng thành phần ngữ pháp, từ cấp độ từ vựng đến cấp độ câu phức, nhằm cung cấp một bộ quy tắc logic (pseudo-code logic) cho việc lập trình máy dịch.

## ---

**2. Phân tích và Thuật toán xử lý Định ngữ (Attributives)**

Định ngữ (Attribute) là thành phần bổ sung ý nghĩa cho danh từ. Đây là "điểm nóng" (hotspot) gây ra sai số nhiều nhất trong dịch máy Trung-Việt do sự đảo ngược vị trí hoàn toàn.

### **2.1. Nguyên tắc Đảo ngược cơ bản**

Trong tiếng Trung, định ngữ _luôn luôn_ đứng trước trung tâm ngữ (có hoặc không có trợ từ kết cấu "的" - de). Trong tiếng Việt, định ngữ thường đứng sau trung tâm ngữ.1
**Logic chung cho Code:**
IF Cấu trúc nguồn == [Modifier] + (的) + [Head Noun]
THEN Cấu trúc đích == [Head Noun] + [Linker] + [Modifier]
Trong đó, Linker (từ nối) trong tiếng Việt có thể là "của", "mà", hoặc rỗng (null), tùy thuộc vào loại từ của Modifier.

### **2.2. Phân loại và Xử lý các dạng Định ngữ**

#### **2.2.1. Định ngữ là Tính từ (Adjective)**

Đây là trường hợp phổ biến nhất. Tiếng Trung dùng Adj + (的) + Noun.

- **Trường hợp 1: Tính từ đơn âm tiết (Monosyllabic)**
  - Tiếng Trung thường không dùng "的".
  - Ví dụ: 红花 (Hóng huā) -> Hoa đỏ.
  - _Logic:_ Swap vị trí trực tiếp. [Adj][Noun] -> [Noun][Adj].
- **Trường hợp 2: Tính từ đa âm tiết hoặc Cụm tính từ**
  - Tiếng Trung bắt buộc hoặc thường dùng "的".
  - Ví dụ: 漂亮的姑娘 (Piàoliang de gūniang - Xinh đẹp de cô gái) -> Cô gái xinh đẹp.
  - Ví dụ: 很聪明的学生 (Hěn cōngmíng de xuéshēng - Rất thông minh de học sinh) -> Học sinh rất thông minh.
  - _Logic:_ [Adj Phrase] + 的 + [Noun] -> [Noun] + [Adj Phrase]. Loại bỏ "的".

#### **2.2.2. Định ngữ sở hữu (Possessive)**

Biểu thị quan hệ sở hữu, luôn dùng "的".

- Ví dụ: 我的书 (Wǒ de shū) -> Sách (của) tôi.
- Ví dụ: 公司的规定 (Gōngsī de guīdìng) -> Quy định của công ty.
- _Logic:_ [N1/Pronoun] + 的 + [N2] -> [N2] + (của) + [N1/Pronoun].
  - _Lưu ý lập trình:_ Nếu N1 là đại từ nhân xưng (tôi, bạn...), từ "của" có thể lược bỏ nếu mối quan hệ thân thiết (Bố tôi - 我爸爸), nhưng an toàn nhất cho máy dịch là giữ "của" hoặc dùng xác suất thống kê ngữ cảnh.

#### **2.2.3. Định ngữ là Danh từ (Categorization)**

Khi danh từ định danh cho danh từ khác (chất liệu, loại hình).

- Ví dụ: 中文书 (Zhōngwén shū) -> Sách tiếng Trung.
- Ví dụ: 木头桌子 (Mùtou zhuōzi) -> Bàn gỗ.
- _Logic:_ [N_attribute] + [N_head] -> [N_head] + [N_attribute]. Không thêm từ nối "của" trong trường hợp chỉ chất liệu hoặc loại hình.

#### **2.2.4. Mệnh đề Định ngữ (Relative Clauses)**

Tiếng Trung đặt cả mệnh đề trước danh từ, kết nối bằng "的". Tiếng Việt đặt mệnh đề sau danh từ, kết nối bằng "mà".5

- Cấu trúc CN: + 的 +
- Cấu trúc VN: + (mà) +
- **Ví dụ:**
  - CN: 我昨天买的书 (Wǒ zuótiān mǎi de shū) -> DE.
  - VN: Quyển sách (mà) tôi mua hôm qua.
- **Ví dụ phức:**
  - CN: 正在跟爸爸说话的那个人 (Zhèngzài gēn bàba shuōhuà de nàge rén) -> [Đang cùng bố nói chuyện] DE [người đó].
  - VN: Cái người (mà) đang nói chuyện với bố đó.

### **2.3. Quy tắc Đảo Định ngữ Đa tầng (Recursive Nested Attributes)**

Một thách thức lớn là khi câu có nhiều tầng định ngữ lồng nhau (A de B de C de D). Quy tắc dịch thường là đảo ngược hoàn toàn thứ tự các cụm.4
**Mô hình:** A 的 B 的 C
**Dịch:** C của B của A

- Ví dụ: 我 朋友 的 爸爸 的 车 (Wǒ péngyǒu de bàba de chē)
  - Phân tích:[Xe]
  - Tiếng Việt: Xe của bố (của) bạn tôi.
- _Thuật toán:_ Cần xác định Trung tâm ngữ cuối cùng (Ultimate Head) là từ danh từ cuối chuỗi, sau đó lần ngược lại các nút con (nodes) phía trước.

### **2.4. Sự chuyển dịch của Đại từ chỉ định và Số từ (Demonstratives & Numerals)**

Đây là điểm khác biệt cấu trúc quan trọng cần code cứng (hard-code).

- **Tiếng Trung:** Đại từ chỉ định (Này/Kia) + Số từ + Lượng từ + Danh từ.
  - Ví dụ: 这 三 本 书 (Zhè sān běn shū) - [Này][Quyển].
- **Tiếng Việt:** Số từ + Lượng từ + Danh từ + Đại từ chỉ định.
  - Ví dụ: Ba quyển sách này.

**Bảng Quy tắc chuyển đổi Cụm Danh từ (NP Mapping Table):**

| Thành phần          | Trật tự Tiếng Trung (Source) | Trật tự Tiếng Việt (Target) | Ví dụ CN       | Dịch VN                  |
| :------------------ | :--------------------------- | :-------------------------- | :------------- | :----------------------- |
| **Đại từ chỉ định** | Vị trí 1 (Đầu cụm)           | Vị trí 4 (Cuối cụm)         | **这**本词典   | Quyển từ điển **này**    |
| **Số từ**           | Vị trí 2                     | Vị trí 1                    | 这**三**本词典 | **Ba** quyển từ điển này |
| **Lượng từ**        | Vị trí 3                     | Vị trí 2                    | 这三**本**词典 | Ba **quyển** từ điển này |
| **Danh từ**         | Vị trí 4                     | Vị trí 3                    | 这三本**词典** | Ba quyển **từ điển** này |

_Lưu ý ngoại lệ:_ Trong tiếng Việt, nếu không có số từ, cấu trúc "Cái [N] này" (Zhè gè [N]) vẫn tuân thủ quy tắc đảo đại từ chỉ định ra sau.6

## ---

**3. Hệ thống Trạng ngữ (Adverbials) và Trật tự Câu**

Trạng ngữ chỉ thời gian, địa điểm, cách thức, mức độ... có vị trí tương đối linh hoạt nhưng tuân theo quy tắc nghiêm ngặt về "Tiền Động từ" (Pre-verbal) hay "Hậu Động từ" (Post-verbal) khác nhau giữa hai ngôn ngữ.

### **3.1. Trạng ngữ chỉ Địa điểm (Locative Adverbials)**

Tiếng Trung ưu tiên cấu trúc giới từ 在 (Zài) + Địa điểm đứng **trước** động từ. Tiếng Việt ưu tiên đứng **sau** động từ.10
**Quy tắc Code:** RULE_LOCATIVE_SHIFT

- Input: Chủ ngữ + [在 + Địa điểm] + Động từ + (Tân ngữ)
- Output: Chủ ngữ + Động từ + (Tân ngữ) + [ở/tại + Địa điểm]

**Ví dụ:**

- CN: 我 **在** 河内 工作 (Wǒ zài Hénèi gōngzuò) -[Làm việc].
- VN: Tôi làm việc **tại** Hà Nội.
- CN: 他 **在** 图书馆 看 书 (Tā zài túshū guǎn kàn shū).
- VN: Anh ấy đọc sách **ở** thư viện.

_Ngoại lệ:_ Khi muốn nhấn mạnh bối cảnh hoặc trong các cấu trúc văn phong trang trọng, tiếng Việt có thể chấp nhận trạng ngữ địa điểm đầu câu (Ví dụ: "Tại Hà Nội, hội nghị đã diễn ra..."), nhưng máy dịch nên ưu tiên cấu trúc phổ quát S-V-O-Locative.

### **3.2. Trạng ngữ chỉ Thời gian (Time Adverbials)**

Tiếng Trung và tiếng Việt khá tương đồng, thời gian thường đứng đầu câu hoặc ngay trước động từ.

- CN: **明天** 我 去 中国 / 我 **明天** 去 中国.
- VN: **Ngày mai** tôi đi Trung Quốc / Tôi **ngày mai** đi Trung Quốc (câu 2 ít tự nhiên hơn một chút nhưng chấp nhận được).
- _Khuyến nghị:_ Giữ nguyên vị trí trạng ngữ thời gian của tiếng Trung khi dịch sang tiếng Việt để đảm bảo an toàn về ngữ nghĩa.

### **3.3. Trạng ngữ chỉ Cách thức với "Địa" (地 - De)**

Cấu trúc Tính từ + 地 + Động từ trong tiếng Trung mô tả hành động được thực hiện như thế nào.

- Tiếng Trung: [Adj] + 地 + [V]
- Tiếng Việt: [V] + (một cách) + [Adj] hoặc [V] + [Adj]

**Ví dụ:**

- CN: 他 **高兴地** 说 (Tā gāoxìng de shuō) - [Anh ấy][Vui vẻ][Nói].
- VN: Anh ấy nói **(một cách) vui vẻ**.
- CN: **努力地** 学习 (Nǔlì de xuéxí).
- VN: Học tập **nỗ lực** / Nỗ lực học tập (Trường hợp này tiếng Việt linh hoạt, nhưng xu hướng V+Adv vẫn mạnh).

### **3.4. Các Giới từ (Coverbs) làm Trạng ngữ**

Tiếng Trung sử dụng nhiều động từ đóng vai trò giới từ (Coverbs) đứng trước động từ chính. Tiếng Việt thường chuyển chúng ra sau.10
**Bảng chuyển đổi Giới từ (Preposition Mapping):**

| Giới từ Tiếng Trung    | Nghĩa       | Cấu trúc Tiếng Trung | Cấu trúc Tiếng Việt           | Ví dụ                                                    |
| :--------------------- | :---------- | :------------------- | :---------------------------- | :------------------------------------------------------- |
| **给 (Gěi)**           | Cho         | A 给 B + V           | A + V + cho + B               | 他**给**我不打电话 -> Anh ấy không gọi điện **cho** tôi. |
| **跟/和 (Gēn/Hé)**     | Với         | A 跟 B + V           | A + V + với/cùng + B          | 我**跟**你去 -> Tôi đi **cùng** bạn.                     |
| **往/向 (Wǎng/Xiàng)** | Về phía     | A 往 [Hướng] + V     | A + V + về phía + [Hướng]     | **往**东走 -> Đi **về** phía đông.                       |
| **离 (Lí)**            | Cách        | A 离 B + [Adj]       | A + cách + B + [Adj]          | 我家**离**这儿很近 -> Nhà tôi **cách** đây rất gần.      |
| **对 (Duì)**           | Với/Đối với | A 对 B + [Adj/V]     | A + [Adj/V] + với/đối với + B | 他**对**我很热情 -> Anh ấy rất nhiệt tình **với** tôi.   |

## ---

**4. Hệ thống Bổ ngữ (Complements) - Phức tạp và Đa dạng**

Bổ ngữ trong tiếng Trung (đứng sau động từ) phong phú và phức tạp hơn tiếng Việt rất nhiều. Đây là phần cần tách lớp (segmentation) và xử lý ngữ nghĩa kỹ lưỡng.12

### **4.1. Bổ ngữ Kết quả (Resultative Complements)**

Cấu trúc V1 + V2/Adj trong đó V2/Adj chỉ kết quả của V1. Tiếng Việt thường có các từ tương đương nhưng cần ánh xạ từ vựng chính xác.15

- **V + 完 (wán - xong):** 吃完 (Ăn xong), 做完 (Làm xong). -> Dịch thẳng: V + xong.
- **V + 懂 (dǒng - hiểu):** 听懂 (Nghe hiểu), 看懂 (Đọc hiểu). -> Dịch thẳng: V + hiểu.
- **V + 见 (jiàn - kiến/thấy):** 看见 (Nhìn thấy), 听见 (Nghe thấy). -> Dịch thẳng: V + thấy.
- **V + 到 (dào - được/đến):** 买到 (Mua được), 找 to (Tìm thấy/được). -> Dịch thành V + được hoặc V + thấy.
- **V + 错 (cuò - sai):** 说错 (Nói sai), 认错 (Nhận nhầm). -> Dịch thẳng: V + sai/nhầm.
- **V + 好 (hǎo - tốt/xong):** 准备好 (Chuẩn bị xong/tốt). -> Dịch thành V + xong.

### **4.2. Bổ ngữ Xu hướng (Directional Complements)**

Bao gồm Xu hướng đơn và Xu hướng kép. Đặc biệt lưu ý quy tắc tách từ khi có tân ngữ chỉ địa điểm.16
**Logic Nhận diện:**

1. **Đơn:** V + 来/去. (Lái/Qù).
   - CN: 进 **来** (Vào đây), 出 **去** (Ra kia).
   - VN: Tương đương.
2. **Kép:** V + + 来/去.
   - Ví dụ: 跑 **回 来** (Pǎo huí lái) -> Chạy **về** (đây).
   - Ví dụ: 拿 **出 去** (Ná chū qù) -> Mang **ra** (kia).

**Xử lý Tân ngữ chèn giữa (Object Splitting Rule):**
Trong tiếng Trung, nếu tân ngữ là địa điểm, nó _bắt buộc_ đứng giữa bổ ngữ xu hướng.

- CN: 他 跑 **回** [家] **来** 了 (Tā pǎo huí [jiā] lái le).
  - Cấu trúc: V + Dir1 + Object + Dir2 + Le.
- VN: Anh ấy chạy **về** [nhà] rồi. (Tiếng Việt thường bỏ "lai/qu" nếu ngữ cảnh rõ ràng, hoặc dùng "chạy về nhà").
- _Quy tắc Code:_ Nếu phát hiện cấu trúc V + Dir1 + N(place) + Dir2, máy cần dịch thành V + Dir1 + N(place) và cân nhắc lược bỏ Dir2 nếu Dir1 đã đủ nghĩa hướng (ví dụ "về" đã hàm ý hướng rồi).

### **4.3. Bổ ngữ Trình độ/Trạng thái (Degree/State Complements) với "得" (De)**

Đây là cấu trúc V + 得 + Adj dùng để đánh giá hành động. Tiếng Việt KHÔNG dùng từ "được" (vì "được" trong tiếng Việt mang nghĩa thụ động hoặc khả năng).
**Quy tắc Code:** RULE_DEGREE_DE

- Input: V + 得 + (Adv) + Adj
- Output: V + (Adv) + Adj HOẶC V + một cách + Adj
- _Lưu ý:_ Từ "đắc" (得) ở đây là hư từ kết cấu, thường **bị lược bỏ** khi dịch sang tiếng Việt.

**Ví dụ:**

- CN: 他 跑 **得** 很 快 (Tā pǎo de hěn kuài).
- VN: Anh ấy chạy rất nhanh. (KHÔNG dịch: Anh ấy chạy được rất nhanh).
- CN: 他 说 汉语 说 **得** 很 好.
- VN: Anh ấy nói tiếng Trung rất tốt.

_Nâng cao:_ Nếu sau "得" là một cụm từ chỉ mức độ cường điệu (Metaphorical).

- CN: 高兴 **得** 跳了起来 (Vui đến mức nhảy cẫng lên).
- Lúc này "得" dịch thành "đến mức" hoặc "đến nỗi".

### **4.4. Bổ ngữ Khả năng (Potential Complements)**

Cấu trúc biểu thị khả năng làm được việc gì đó.

- **Khẳng định:** V + 得 + Result. -> Dịch: V + được + Result hoặc V + nổi.
  - CN: 看 **得** 清楚 (Nhìn được rõ).
  - CN: 吃 **得** 完 (Ăn hết / Ăn nổi).
- **Phủ định:** V + 不 + Result. -> Dịch: V + không + Result.
  - CN: 看 **不** 清楚 (Nhìn không rõ).
  - CN: 听 **不** 懂 (Nghe không hiểu).
  - CN: 受 **不** 了 (Shòu bu liǎo - Chịu không nổi).

### **4.5. Bổ ngữ Thời lượng và Động lượng**

- **Thời lượng (Duration):** Tiếng Trung có thể tách động từ và tân ngữ để chèn thời gian. Tiếng Việt đặt thời gian sau cùng.
  - CN: 我 等 了 你 **三 个 小时**. (Tôi đợi bạn 3 tiếng). -> Tương đồng.
  - CN: 游 了 **三 个 小时** 泳 (Yóu le sān gè xiǎoshí yǒng - Bơi 3 tiếng hồ bơi).
    - Đây là động từ ly hợp (Separable Verb).
    - VN: Bơi 3 tiếng đồng hồ. (Tân ngữ "vịnh/bơi" bị lược bỏ hoặc gộp).
- **Động lượng (Frequency):** V + Số lần.
  - CN: 去 过 **三 次**. -> VN: Đi qua **3 lần**.

## ---

**5. Các Mẫu Câu Đặc Biệt (Special Sentence Patterns)**

Đây là những cấu trúc làm thay đổi trật tự SVO thông thường, yêu cầu thuật toán nhận diện mẫu (Pattern Matching) riêng biệt.

### **5.1. Câu chữ "Pả" (把 - Bǎ) - Câu Xử lý**

Dùng để nhấn mạnh tác động lên tân ngữ, đưa tân ngữ lên trước động từ.

- Cấu trúc CN: Chủ ngữ + 把 + Tân ngữ + Động từ + Thành phần khác (Kết quả/Hướng).
- Cấu trúc VN: Tiếng Việt không có cấu trúc tương đương hoàn toàn. Thường dịch về dạng SVO hoặc dùng từ "đem/lấy" để nhấn mạnh.

**Thuật toán Code:** RULE_BA_CONVERSION

1. Nhận diện: S + 把 + O + V + Comp.
2. Chuyển đổi 1 (Tự nhiên): S + V + Comp + O.
3. Chuyển đổi 2 (Nhấn mạnh): S + đem/lấy + O + V + Comp.

**Ví dụ:**

- CN: 我 **把** 书 看 完了 (Wǒ bǎ shū kàn wán le).
  - Cách 1: Tôi đọc xong sách rồi. (SVO).
  - Cách 2: Tôi **đem** sách đọc xong rồi. (Ít dùng).
- CN: 请 **把** 门 打开 (Qǐng bǎ mén dǎkāi).
  - VN: Xin hãy mở cửa ra. (Bỏ "把", đưa "Cửa" về sau "Mở").
- CN: 他 **把** 钱 丢 了.
  - VN: Anh ấy làm mất tiền rồi. (Động từ "Diū" thường dịch kèm "làm mất").

### **5.2. Câu chữ "Bị" (被 - Bèi) - Câu Bị động**

Tương đương với câu bị động trong tiếng Việt.

- Cấu trúc: Chủ ngữ (Người bị hại) + 被 + Tác nhân + Động từ.
- Dịch: Dùng "bị" (tiêu cực) hoặc "được" (tích cực).19

**Ví dụ:**

- CN: 我的自行车 **被** 偷 了 (Xe đạp của tôi bị trộm rồi). -> Dùng "bị".
- CN: 他 **被** 选 为 班长 (Anh ấy được bầu làm lớp trưởng). -> Dùng "được" (vì đây là điều tốt).
- _Logic Code:_ Cần một từ điển phân loại sắc thái động từ (Sentiment Analysis) để chọn "bị" hay "được". Nếu không xác định được, mặc định là "bị" cho các động từ gây hại, "được" cho các động từ nhận lợi ích.

### **5.3. Câu So sánh với "Bỉ" (比 - Bǐ)**

- Cấu trúc CN: A + 比 + B + Adj.
- Cấu trúc VN: A + Adj + hơn + B.

**Quy tắc Code:** RULE_COMPARISON_SHIFT

- Input: A + 比 + B + Adj
- Output: A + Adj + hơn + B

**Ví dụ:**

- CN: 他 **比** 我 高 (Tā bǐ wǒ gāo). -> VN: Anh ấy cao **hơn** tôi.
- CN: 今天 **比** 昨天 冷. -> VN: Hôm nay lạnh **hơn** hôm qua.21
- _Mở rộng:_ A + 比 + B + 更/还 + Adj (A còn... hơn B).
  - CN: 我 比 他 **更** 喜欢 音乐. -> VN: Tôi **càng/còn** thích âm nhạc **hơn** anh ấy.

### **5.4. Câu Tồn hiện (Existential Sentences)**

Mô tả sự tồn tại của vật tại địa điểm.

- Cấu trúc CN: Địa điểm + Động từ + (Zhe/Le) + Danh từ.
- Cấu trúc VN: (Trên/Trong) + Địa điểm + có + Danh từ hoặc Địa điểm + Động từ + Danh từ.

**Ví dụ:**

- CN: 桌子上 放 **着** 一本书 (Zhuōzi shàng fàng zhe yī běn shū).
  - VN: Trên bàn (có) đặt một quyển sách. (Thêm từ "có" làm rõ nghĩa tồn tại).22
- CN: 前面 来 **了** 一个 人.
  - VN: Phía trước có một người đang tới.

### **5.5. Câu Liên động (Serial Verb Constructions)**

Một chủ ngữ thực hiện chuỗi hành động. Trật tự tiếng Trung và tiếng Việt giống nhau (theo trật tự thời gian), nên dịch máy dễ dàng xử lý theo tuyến tính (linear).23

- CN: 他 去 商店 买 东西. -> VN: Anh ấy đi cửa hàng mua đồ.
- CN: 坐 飞机 去 (Ngồi máy bay đi). -> VN: Đi bằng máy bay. (Lưu ý: Tiếng Trung dùng "Ngồi + Phương tiện", tiếng Việt dùng "Đi + bằng + Phương tiện").

## ---

**6. Xử lý Từ loại và Hình thái từ Đặc thù**

### **6.1. Động từ Ly hợp (Separable Verbs)**

Đây là ác mộng của dịch máy nếu chỉ dịch từng từ (word-for-word). Động từ ly hợp (như 见面 - gặp mặt, 睡觉 - ngủ, 结婚 - kết hôn) thực chất là kết cấu Động từ - Tân ngữ (V-O) nhưng mang nghĩa của một từ đơn.24
**Vấn đề:** Các thành phần khác (thời lượng, trợ từ động thái) thường chêm vào giữa.

- CN: 结 **了** 婚 (Jié le hūn). -> VN: Kết hôn rồi (Không nói: Kết rồi hôn).
- CN: 见 **个** 面. -> VN: Gặp mặt (một chút).
- CN: 洗 **三 个 小时** 澡. -> VN: Tắm 3 tiếng đồng hồ.

**Giải pháp Code:**

1. **Danh sách Stop-list:** Xây dựng từ điển các động từ ly hợp phổ biến.
2. **Hợp nhất:** Khi gặp V_sep + (Component) + O_sep, hãy coi V_sep + O_sep là động từ chính, và dịch Component như bổ ngữ thời lượng hoặc động lượng.

### **6.2. Động từ Năng nguyện (Modal Verbs)**

Đứng trước động từ chính, dịch khá tương đồng.27

| Tiếng Trung   | Phiên âm | Tiếng Việt         | Ghi chú                                                    |
| :------------ | :------- | :----------------- | :--------------------------------------------------------- |
| **想**        | Xiǎng    | Muốn / Nhớ         | "Nhớ" khi có tân ngữ người/nơi chốn, "Muốn" khi + Động từ. |
| **要**        | Yào      | Muốn / Cần / Sắp   | Đa nghĩa, cần xét ngữ cảnh (tương lai hay nhu cầu).        |
| **能 / 能够** | Néng     | Có thể / Làm được  | Chỉ năng lực khách quan.                                   |
| **可以**      | Kěyǐ     | Có thể / Được phép | Chỉ sự cho phép hoặc khả năng.                             |
| **会**        | Huì      | Biết / Sẽ          | "Biết" (kỹ năng), "Sẽ" (tương lai).                        |
| **应该**      | Yīnggāi  | Nên                | Lời khuyên.                                                |

### **6.3. Trợ từ Động thái (Aspect Particles): Le, Zhe, Guo**

Tiếng Trung không có thì (tense), dùng trợ từ để chỉ thể (aspect).

- **了 (Le):**
  - Sau động từ (V + Le): Chỉ hành động hoàn tất. -> Dịch là "**đã** V" hoặc "V **xong/rồi**".
  - Cuối câu (Sentence + Le): Chỉ sự thay đổi trạng thái. -> Dịch là "**rồi**".
  - _Ví dụ:_ 下雨 **了** (Mưa **rồi** - trước đó không mưa).
- **着 (Zhe):**
  - Chỉ hành động đang tiếp diễn hoặc trạng thái kéo dài. -> Dịch là "**đang**".
  - _Ví dụ:_ 他 看 **着** 我 (Anh ấy **đang** nhìn tôi). 门 开 **着** (Cửa **đang** mở).
- **过 (Guo):**
  - Chỉ trải nghiệm trong quá khứ. -> Dịch là "**đã từng**" hoặc "**qua**".
  - _Ví dụ:_ 我 去 **过** 中国 (Tôi **đã từng** đi Trung Quốc).

### **6.4. Câu hỏi Chính phản (A-not-A Questions)**

Cấu trúc lặp lại động từ để hỏi: V + 不/没 + V.

- CN: 你 去 不 去? (Nǐ qù bu qù?).
- VN: Bạn có đi không? (Không dịch: Bạn đi không đi?).
- **Quy tắc Code:** V + 不 + V -> Có + V + không?.
- Ví dụ: 好不好 (Tốt không?), 吃没吃 (Ăn chưa?).28

## ---

**7. Cấu trúc Câu Phức và Liên từ (Complex Sentences)**

Xử lý các cặp liên từ (Paired Conjunctions) là bước cuối cùng để hoàn thiện câu ghép.29
**Các cặp quan trọng:**

1. **Nguyên nhân - Kết quả:**
   - 因为 (Yīnwèi)... 所以 (suǒyǐ)... -> Bởi vì... cho nên...
2. **Chuyển ngoặt (Adversative):**
   - 虽然 (Suīrán)... 但是/可是 (dànshì/kěshì)... -> Tuy... nhưng...
3. **Điều kiện:**
   - 只要 (Zhǐyào)... 就 (jiù)... -> Chỉ cần... là...
   - 只有 (Zhǐyǒu)... 才 (cái)... -> Chỉ có... mới...
   - 如果 (Rúguǒ)... 就 (jiù)... -> Nếu... thì...
4. **Tăng tiến:**
   - 不但 (Bùdàn)... 而且 (érqiě)... -> Không những... mà còn...

## ---

**8. Kết luận và Khuyến nghị Triển khai Code**

Để xây dựng máy dịch Trung-Việt hiệu quả dựa trên các phân tích trên, kiến trúc hệ thống nên tuân theo quy trình đường ống (pipeline) sau:

1. **Phân tách từ (Word Segmentation):** Sử dụng thư viện chuyên dụng (như Jieba, HanLP) để tách từ tiếng Trung, đặc biệt nhận diện Động từ ly hợp và Tên riêng.
2. **Gán nhãn từ loại (POS Tagging):** Xác định danh từ, động từ, tính từ, hư từ (de, le, zhe...).
3. **Phân tích cú pháp (Syntactic Parsing):** Xây dựng cây cú pháp để xác định các cụm NP, VP.
4. **Module Chuyển đổi Cấu trúc (Transformation Engine):** Áp dụng các luật (Rules) đã phân tích:
   - **Rule 1 (Priority High):** Đảo ngược cụm danh từ chứa "的" hoặc định ngữ tính từ.
   - **Rule 2:** Đẩy trạng ngữ chỉ địa điểm (Zài + Loc) và giới từ (Gěi/Gēn + Obj) ra sau động từ.
   - **Rule 3:** Xử lý câu chữ "Bả" (đưa Object về sau Verb).
   - **Rule 4:** Xử lý bổ ngữ chỉ mức độ (V + de + Adj -> V + rất + Adj).
   - **Rule 5:** Chuyển đổi so sánh (Bǐ -> Hơn).
5. **Ánh xạ từ vựng và Làm mịn (Lexical Mapping & Smoothing):**
   - Thêm các hư từ tiếng Việt (của, cái, những, mà) vào vị trí thích hợp để câu văn tự nhiên.
   - Chọn nghĩa của "Le/Zhe/Guo" dựa trên vị trí trong câu.

Việc kết hợp chặt chẽ giữa các quy tắc ngữ pháp cứng (hard rules) và từ điển ngoại lệ (exception dictionary) sẽ giúp máy dịch xử lý tốt khoảng 80-90% các cấu trúc câu phổ biến trong văn bản thông thường.

#### **Works cited**

1. PHÂN TÍCH SO SÁNH ĐỊNH NGỮ GIỮA TIẾNG VIỆT VÀ TIẾNG TRUNG - Neliti, accessed February 2, 2026, [https://media.neliti.com/media/publications/452479-analysis-and-comparison-of-attibutives-b-342d0920.pdf](https://media.neliti.com/media/publications/452479-analysis-and-comparison-of-attibutives-b-342d0920.pdf)
2. Vietnamese to Chinese Machine Translation via Chinese Character as Pivot - ACL Anthology, accessed February 2, 2026, [https://aclanthology.org/Y13-1024.pdf](https://aclanthology.org/Y13-1024.pdf)
3. Syntax-Based Chinese-Vietnamese Tree-to-Tree Statistical Machine Translation with Bilingual Features | Semantic Scholar, accessed February 2, 2026, [https://www.semanticscholar.org/paper/Syntax-Based-Chinese-Vietnamese-Tree-to-Tree-with-Gao-Huang/266ddcf0692623ca166f4f5d769af402d3d13eca](https://www.semanticscholar.org/paper/Syntax-Based-Chinese-Vietnamese-Tree-to-Tree-with-Gao-Huang/266ddcf0692623ca166f4f5d769af402d3d13eca)
4. Định ngữ trong tiếng Trung - TIẾNG HOA BÌNH DƯƠNG, accessed February 2, 2026, [http://www.tienghoabinhduong.vn/2020/09/inh-ngu-trong-tieng-trung.html](http://www.tienghoabinhduong.vn/2020/09/inh-ngu-trong-tieng-trung.html)
5. Quy tắc sắp xếp trật tự từ trong tiếng Trung quan trọng - Prep, accessed February 2, 2026, [https://prepedu.com/vi/blog/trat-tu-tu-trong-tieng-trung](https://prepedu.com/vi/blog/trat-tu-tu-trong-tieng-trung)
6. Vietnamese grammar - Wikipedia, accessed February 2, 2026, [https://en.wikipedia.org/wiki/Vietnamese_grammar](https://en.wikipedia.org/wiki/Vietnamese_grammar)
7. Vietnamese Classifiers: Cái, Con & Vietnamese Grammar Guide - Migaku, accessed February 2, 2026, [https://migaku.com/blog/language-fun/vietnamese-classifiers](https://migaku.com/blog/language-fun/vietnamese-classifiers)
8. Vietnamese Sentence Structure: Complete Grammar Guide - Migaku, accessed February 2, 2026, [https://migaku.com/blog/language-fun/vietnamese-sentence-structure](https://migaku.com/blog/language-fun/vietnamese-sentence-structure)
9. Language Guidelines – Vietnamese - Unbabel Community Support, accessed February 2, 2026, [https://help.unbabel.com/hc/en-us/articles/360022945614-Language-Guidelines-Vietnamese](https://help.unbabel.com/hc/en-us/articles/360022945614-Language-Guidelines-Vietnamese)
10. 7 quy tắc đặt câu trong tiếng Trung - Dịch thuật HACO, accessed February 2, 2026, [https://dichthuathaco.com.vn/7-quy-tac-dat-cau-trong-tieng-trung-trat-tu-cau-tong-tieng-trung.html](https://dichthuathaco.com.vn/7-quy-tac-dat-cau-trong-tieng-trung-trat-tu-cau-tong-tieng-trung.html)
11. Trạng ngữ trong tiếng Trung| Ngữ pháp quan trọng không thể bỏ lỡ, accessed February 2, 2026, [https://chinese.edu.vn/trang-ngu-trong-tieng-trung.html](https://chinese.edu.vn/trang-ngu-trong-tieng-trung.html)
12. CÁC LOẠI BỔ NGỮ TRONG TIẾNG TRUNG #2 BỔ NGỮ KẾT QUẢ | NGỮ PHÁP TIẾNG TRUNG - YouTube, accessed February 2, 2026, [https://www.youtube.com/watch?v=vIUN8XUZXoA](https://www.youtube.com/watch?v=vIUN8XUZXoA)
13. Tổng hợp các loại Bổ ngữ trong tiếng Trung, accessed February 2, 2026, [https://thanhmaihsk.edu.vn/tong-hop-cac-loai-bo-ngu-trong-tieng-trung/](https://thanhmaihsk.edu.vn/tong-hop-cac-loai-bo-ngu-trong-tieng-trung/)
14. Tìm hiểu về các loại và cách sử dụng bổ ngữ trong tiếng Trung, accessed February 2, 2026, [https://ctihsk.edu.vn/bo-ngu-trong-tieng-trung/](https://ctihsk.edu.vn/bo-ngu-trong-tieng-trung/)
15. Bổ ngữ kết quả - tiengtrungthuonghai.vn - Tiếng Trung Thượng Hải, accessed February 2, 2026, [https://tiengtrungthuonghai.vn/tuhoctiengtrung/bo-ngu-ket-qua-trong-tieng-trung/](https://tiengtrungthuonghai.vn/tuhoctiengtrung/bo-ngu-ket-qua-trong-tieng-trung/)
16. Cách dùng bổ ngữ xu hướng trong tiếng Trung chi tiết! - Prep, accessed February 2, 2026, [https://prepedu.com/vi/blog/bo-ngu-xu-huong-trong-tieng-trung](https://prepedu.com/vi/blog/bo-ngu-xu-huong-trong-tieng-trung)
17. Thực hành bổ ngữ xu hướng trong tiếng Trung - Phuong Nam Education, accessed February 2, 2026, [https://hoctiengtrungquoc.com/noi-dung/thuc-hanh-bo-ngu-xu-huong-trong-tieng-trung.html](https://hoctiengtrungquoc.com/noi-dung/thuc-hanh-bo-ngu-xu-huong-trong-tieng-trung.html)
18. Bổ ngữ xu hướng trong tiếng Trung là gì? Phân loại và cách dùng, accessed February 2, 2026, [https://ctihsk.edu.vn/bo-ngu-xu-huong-trong-tieng-trung-la-gi-phan-loai-va-cach-dung/](https://ctihsk.edu.vn/bo-ngu-xu-huong-trong-tieng-trung-la-gi-phan-loai-va-cach-dung/)
19. Cách dùng câu chữ “被”- câu bị động trong Tiếng Trung (被字句）, accessed February 2, 2026, [https://www.tiengtrungnihao.com/post/c%C3%A1ch-d%C3%B9ng-c%C3%A2u-ch%E1%BB%AF-%E8%A2%AB-c%C3%A2u-b%E1%BB%8B-%C4%91%E1%BB%99ng-trong-ti%E1%BA%BFng-trung-%E8%A2%AB%E5%AD%97%E5%8F%A5%EF%BC%89](https://www.tiengtrungnihao.com/post/c%C3%A1ch-d%C3%B9ng-c%C3%A2u-ch%E1%BB%AF-%E8%A2%AB-c%C3%A2u-b%E1%BB%8B-%C4%91%E1%BB%99ng-trong-ti%E1%BA%BFng-trung-%E8%A2%AB%E5%AD%97%E5%8F%A5%EF%BC%89)
20. Chinh phục ngữ pháp tiếng Trung về câu bị động, accessed February 2, 2026, [https://trungtamtiengtrung.edu.vn/blog/ngu-phap-tieng-trung-ve-cau-bi-dong-1192/](https://trungtamtiengtrung.edu.vn/blog/ngu-phap-tieng-trung-ve-cau-bi-dong-1192/)
21. Cấu trúc 4 mẫu câu so sánh trong tiếng Trung quan trọng!, accessed February 2, 2026, [https://prepedu.com/vi/blog/cau-so-sanh-trong-tieng-trung](https://prepedu.com/vi/blog/cau-so-sanh-trong-tieng-trung)
22. Cách dùng 2 loại câu tồn hiện trong tiếng Trung chi tiết - Prep, accessed February 2, 2026, [https://prepedu.com/vi/blog/cau-ton-hien-tieng-trung](https://prepedu.com/vi/blog/cau-ton-hien-tieng-trung)
23. Cách dùng câu liên động trong tiếng Trung chi tiết từ A-Z, accessed February 2, 2026, [https://prepedu.com/vi/blog/cau-lien-dong-trong-tieng-trung](https://prepedu.com/vi/blog/cau-lien-dong-trong-tieng-trung)
24. Cách dùng động từ ly hợp trong tiếng Trung, accessed February 2, 2026, [https://trungtamtiengtrung.edu.vn/blog/ngu-phap-tieng-trung-cach-dung-dong-tu-li-hop-cuc-de-nho-1067/](https://trungtamtiengtrung.edu.vn/blog/ngu-phap-tieng-trung-cach-dung-dong-tu-li-hop-cuc-de-nho-1067/)
25. Ngữ pháp về động từ ly hợp tiếng Trung bạn cần biết, accessed February 2, 2026, [https://tiengtrunghsk.vn/ngu-phap-ve-dong-tu-ly-hop-tieng-trung/](https://tiengtrunghsk.vn/ngu-phap-ve-dong-tu-ly-hop-tieng-trung/)
26. Động từ li hợp: Cấu trúc, cách dùng, quy tắc và bài tập vận dụng! - Prep, accessed February 2, 2026, [https://prepedu.com/vi/blog/dong-tu-li-hop](https://prepedu.com/vi/blog/dong-tu-li-hop)
27. Ngữ pháp tiếng Trung động từ năng nguyện, accessed February 2, 2026, [http://www.tiengtrunghoanglien.com.vn/ngu-phap-tieng-trung-dong-tu-nang-nguyen](http://www.tiengtrunghoanglien.com.vn/ngu-phap-tieng-trung-dong-tu-nang-nguyen)
28. Câu hỏi chính phản trong tiếng Trung: Cấu trúc, cách dùng! - Prep, accessed February 2, 2026, [https://prepedu.com/vi/blog/cau-hoi-chinh-phan-trong-tieng-trung](https://prepedu.com/vi/blog/cau-hoi-chinh-phan-trong-tieng-trung)
29. Cách sử dụng liên từ thông dụng trong tiếng Trung - Thanhmaihsk, accessed February 2, 2026, [https://thanhmaihsk.edu.vn/cach-su-dung-lien-tu-trong-tieng-trung/](https://thanhmaihsk.edu.vn/cach-su-dung-lien-tu-trong-tieng-trung/)
30. Cách dùng 10 loại liên từ trong tiếng Trung thông dụng! - Prep, accessed February 2, 2026, [https://prepedu.com/vi/blog/lien-tu-trong-tieng-trung](https://prepedu.com/vi/blog/lien-tu-trong-tieng-trung)
31. 25 Liên Từ Tiếng Trung Phổ Biến Nhất, accessed February 2, 2026, [https://yuexin.edu.vn/25-lien-tu-tieng-trung-pho-bien-nhat.htm](https://yuexin.edu.vn/25-lien-tu-tieng-trung-pho-bien-nhat.htm)
32. Ngữ pháp tiếng Trung: Các loại câu phức (Phần 1) - Gioitiengtrung, accessed February 2, 2026, [https://gioitiengtrung.vn/ngu-phap-tieng-trung-cac-loai-cau-phuc-phan-1-](https://gioitiengtrung.vn/ngu-phap-tieng-trung-cac-loai-cau-phuc-phan-1-)
