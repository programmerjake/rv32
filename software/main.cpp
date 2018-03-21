/*
 * Copyright 2018 Jacob Lifshay
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */
#include <cstdint>
#include <limits>

inline void putchar(int ch)
{
#ifdef EMULATE_TARGET
    switch(ch)
    {
    case 0xB2:
        __builtin_printf("\u2593");
        break;
    case 0xB0:
        __builtin_printf("\u2591");
        break;
    default:
        __builtin_printf("%c", (char)ch);
    }
#else
    *reinterpret_cast<volatile char *>(0x80000000) = ch;
#endif
}

inline void write_hex_digit(int value)
{
    putchar("0123456789ABCDEF"[value]);
}

inline void write_hex_u8(std::uint8_t value)
{
    write_hex_digit(value >> 4);
    write_hex_digit(value & 0xF);
}

inline void write_hex_u16(std::uint16_t value)
{
    write_hex_u8(value >> 8);
    write_hex_u8(value & 0xFF);
}

inline void write_hex_u32(std::uint32_t value)
{
    write_hex_u16(value >> 16);
    write_hex_u16(value & 0xFFFF);
}

inline std::uint32_t read_gpio()
{
#ifdef EMULATE_TARGET
    return 0x0;
#else
    return *reinterpret_cast<volatile std::uint32_t *>(0x80000010);
#endif
}

inline void write_gpio(std::uint32_t value)
{
#ifndef EMULATE_TARGET
    *reinterpret_cast<volatile std::uint32_t *>(0x80000010) = value;
#endif
}

constexpr std::uint32_t switch_2_mask = 0x200;
constexpr std::uint32_t switch_3_mask = 0x400;

inline void puts(const char *str)
{
    while(*str)
        putchar(*str++);
}

constexpr std::size_t screen_x_size = 800 / 8;
constexpr std::size_t screen_y_size = 600 / 8;

template <typename T>
struct get_double_length_type;

template <>
struct get_double_length_type<std::uint8_t>
{
    typedef std::uint16_t type;
};

template <>
struct get_double_length_type<std::uint16_t>
{
    typedef std::uint32_t type;
};

template <>
struct get_double_length_type<std::uint32_t>
{
    typedef std::uint64_t type;
};

template <>
struct get_double_length_type<std::int8_t>
{
    typedef std::int16_t type;
};

template <>
struct get_double_length_type<std::int16_t>
{
    typedef std::int32_t type;
};

template <>
struct get_double_length_type<std::int32_t>
{
    typedef std::int64_t type;
};

template <typename T>
constexpr T bidirectional_shift_left(T value, int amount) noexcept
{
    int max_shift = std::numeric_limits<T>::digits;
    if(amount <= -max_shift)
        return value < 0 ? -1 : 0;
    if(amount < 0)
        return value >> -amount;
    return value << amount;
}

template <typename T>
constexpr T bidirectional_shift_right(T value, int amount) noexcept
{
    return bidirectional_shift_left(value, -amount);
}

template <typename T = std::int32_t, std::size_t FractionalBits = 16>
class Fixed
{
public:
    typedef T underlying_type;
    typedef typename get_double_length_type<T>::type double_length_type;
    static constexpr std::size_t total_bits = std::numeric_limits<T>::digits;
    static constexpr std::size_t fractional_bits = FractionalBits;
    static constexpr std::size_t integer_bits = total_bits - fractional_bits;
    static constexpr T fraction_mask = (static_cast<T>(1) << fractional_bits) - 1;
    static constexpr T integer_mask = ~fraction_mask;
    static_assert(total_bits >= fractional_bits, "");

private:
    underlying_type value;

public:
    constexpr Fixed() noexcept : value(0)
    {
    }
    constexpr Fixed(signed char v) noexcept : value(static_cast<T>(v) << fractional_bits)
    {
    }
    constexpr Fixed(short v) noexcept : value(static_cast<T>(v) << fractional_bits)
    {
    }
    constexpr Fixed(int v) noexcept : value(static_cast<T>(v) << fractional_bits)
    {
    }
    constexpr Fixed(long v) noexcept : value(static_cast<T>(v) << fractional_bits)
    {
    }
    constexpr Fixed(long long v) noexcept : value(static_cast<T>(v) << fractional_bits)
    {
    }
    constexpr Fixed(unsigned char v) noexcept : value(static_cast<T>(v) << fractional_bits)
    {
    }
    constexpr Fixed(char v) noexcept : value(static_cast<T>(v) << fractional_bits)
    {
    }
    constexpr Fixed(unsigned short v) noexcept : value(static_cast<T>(v) << fractional_bits)
    {
    }
    constexpr Fixed(unsigned v) noexcept : value(static_cast<T>(v) << fractional_bits)
    {
    }
    constexpr Fixed(unsigned long v) noexcept : value(static_cast<T>(v) << fractional_bits)
    {
    }
    constexpr Fixed(unsigned long long v) noexcept : value(static_cast<T>(v) << fractional_bits)
    {
    }
    constexpr Fixed(float v) noexcept
        : value(static_cast<T>(static_cast<float>(1ULL << fractional_bits) * v))
    {
    }
    constexpr Fixed(double v) noexcept
        : value(static_cast<T>(static_cast<double>(1ULL << fractional_bits) * v))
    {
    }
    constexpr explicit operator T() const noexcept
    {
        if(value < 0)
            return (value + fraction_mask) >> fractional_bits;
        return value >> fractional_bits;
    }
    constexpr explicit operator double() const noexcept
    {
        return value * (1.0 / (1ULL << fractional_bits));
    }
    static constexpr Fixed make(T underlying_value) noexcept
    {
        Fixed retval;
        retval.value = underlying_value;
        return retval;
    }
    constexpr Fixed operator+() const noexcept
    {
        return *this;
    }
    constexpr Fixed operator-() const noexcept
    {
        return make(-value);
    }
    friend constexpr Fixed operator+(Fixed a, Fixed b) noexcept
    {
        return make(a.value + b.value);
    }
    friend constexpr Fixed operator-(Fixed a, Fixed b) noexcept
    {
        return make(a.value - b.value);
    }
    friend constexpr Fixed operator*(Fixed a, Fixed b) noexcept
    {
        return make(static_cast<double_length_type>(a.value) * b.value >> fractional_bits);
    }
    friend constexpr Fixed operator/(Fixed a, Fixed b) noexcept
    {
        return make((static_cast<double_length_type>(a.value) << fractional_bits) / b.value);
    }
    constexpr Fixed &operator+=(Fixed rt) noexcept
    {
        return *this = *this + rt;
    }
    constexpr Fixed &operator-=(Fixed rt) noexcept
    {
        return *this = *this - rt;
    }
    constexpr Fixed &operator*=(Fixed rt) noexcept
    {
        return *this = *this * rt;
    }
    constexpr Fixed &operator/=(Fixed rt) noexcept
    {
        return *this = *this / rt;
    }
    constexpr T underlying_value() const noexcept
    {
        return value;
    }
    friend constexpr bool operator==(Fixed a, Fixed b) noexcept
    {
        return a.value == b.value;
    }
    friend constexpr bool operator!=(Fixed a, Fixed b) noexcept
    {
        return a.value != b.value;
    }
    friend constexpr bool operator<=(Fixed a, Fixed b) noexcept
    {
        return a.value <= b.value;
    }
    friend constexpr bool operator>=(Fixed a, Fixed b) noexcept
    {
        return a.value >= b.value;
    }
    friend constexpr bool operator<(Fixed a, Fixed b) noexcept
    {
        return a.value < b.value;
    }
    friend constexpr bool operator>(Fixed a, Fixed b) noexcept
    {
        return a.value > b.value;
    }
    friend constexpr Fixed floor(Fixed v) noexcept
    {
        v.value &= integer_mask;
        return v;
    }
    friend constexpr Fixed fracf(Fixed v) noexcept
    {
        v.value &= fraction_mask;
        return v;
    }
    friend constexpr Fixed ceil(Fixed v) noexcept
    {
        v.value += fraction_mask;
        return floor(v);
    }
    friend constexpr Fixed round(Fixed v) noexcept
    {
        constexpr Fixed one_half = 0.5;
        v += one_half;
        return floor(v);
    }
    friend constexpr T floori(Fixed v) noexcept
    {
        return v.value >> fractional_bits;
    }
    friend constexpr T ceili(Fixed v) noexcept
    {
        v.value += fraction_mask;
        return floori(v);
    }
    friend constexpr T roundi(Fixed v) noexcept
    {
        constexpr Fixed one_half = 0.5;
        v += one_half;
        return floori(v);
    }
    friend constexpr Fixed abs(Fixed v) noexcept
    {
        if(v.value < 0)
            return -v;
        return v;
    }
    friend constexpr Fixed sqrt(Fixed v) noexcept
    {
        if(v <= 0)
            return 0;
        Fixed guess = 0;
        double_length_type guess_squared = 0;
        for(int bit_index = (integer_bits + 1) / 2; bit_index >= -static_cast<int>(fractional_bits);
            bit_index--)
        {
            Fixed new_guess = guess + make(static_cast<T>(1) << (bit_index + fractional_bits));
            double_length_type new_guess_squared = guess_squared;
            new_guess_squared += bidirectional_shift_left(
                static_cast<double_length_type>(guess.value), bit_index + 1);
            new_guess_squared += bidirectional_shift_left(
                static_cast<double_length_type>(Fixed(1).value), 2 * bit_index);
            if(new_guess_squared < v.value)
            {
                guess = new_guess;
                guess_squared = new_guess_squared;
            }
            else if(new_guess_squared == v.value)
                return new_guess;
        }
        return guess;
    }
};

enum class Block : char
{
    Empty = ' ',
    Wall = '|',
    End = 'X'
};

constexpr double constexpr_sin2pi(double x) noexcept
{
    x -= static_cast<long long>(x);
    if(x < 0)
        x += 1;
    if(x == 0)
        return 0;
    if(x == 0.25)
        return 1;
    if(x == 0.5)
        return 0;
    if(x == 0.75)
        return -1;
    double x2 = x * x;
    const double coefficients[] = {
        1.5873670538243229332222957023504872028033458258785e-8,
        -3.2649283479971170585768247133750680886632233028762e-7,
        5.8056524029499061679627827975252772363553363262495e-6,
        -8.8235335992430051344844841671401871742374913922057e-5,
        1.1309237482517961877702180414488525515732161905954e-3,
        -1.2031585942120627233202567845286556653885737182738e-2,
        1.0422916220813984117271044898760411097029995316417e-1,
        -7.1812230177850051223174027860686238053986168884284e-1,
        3.8199525848482821277337920673404661254406128731422,
        -1.5094642576822990391826616232531520514481435107371e1,
        4.205869394489765314498681114813355254161277992845e1,
        -7.6705859753061385841630641093893125889966539055122e1,
        8.1605249276075054203397682678249495061413521767487e1,
        -4.1341702240399760233968420089468526936300384754514e1,
        6.2831853071795864769252867665590057683943387987502,
    };
    double v = 0;
    for(double coeff : coefficients)
        v = v * x2 + coeff;
    return x * v;
}

constexpr double constexpr_cos2pi(double x) noexcept
{
    x -= static_cast<long long>(x);
    x += 0.25;
    return constexpr_sin2pi(x);
}

template <std::size_t N = 65>
struct SinCosList
{
    static_assert(N > 1, "");
    constexpr std::size_t size() const noexcept
    {
        return N;
    }
    Fixed<> sin_table[N];
    constexpr SinCosList() noexcept : sin_table{}
    {
        for(std::size_t i = 0; i < N; i++)
        {
            double rotations = i / (4.0 * (N - 1));
            sin_table[i] = constexpr_sin2pi(rotations);
        }
    }
    constexpr void get(Fixed<> &sin_out, Fixed<> &cos_out, Fixed<> rotations) const noexcept
    {
        rotations = fracf(rotations) * 4;
        int quadrent = floori(rotations);
        rotations = (N - 1) * fracf(rotations);
        auto int_part = floori(rotations);
        auto fraction = fracf(rotations);
        auto sin_value =
            sin_table[int_part] + fraction * (sin_table[int_part + 1] - sin_table[int_part]);
        auto cos_value =
            sin_table[N - 1 - int_part]
            + fraction * (sin_table[N - 1 - int_part - 1] - sin_table[N - 1 - int_part]);
        switch(quadrent)
        {
        case 1:
            sin_out = cos_value;
            cos_out = -sin_value;
            break;
        case 2:
            sin_out = -sin_value;
            cos_out = -cos_value;
            break;
        case 3:
            sin_out = -cos_value;
            cos_out = sin_value;
            break;
        default:
            sin_out = sin_value;
            cos_out = cos_value;
            break;
        }
    }
    constexpr Fixed<> get_sin(Fixed<> rotations) const noexcept
    {
        Fixed<> sin, cos;
        get(sin, cos, rotations);
        return sin;
    }
    constexpr Fixed<> get_cos(Fixed<> rotations) const noexcept
    {
        Fixed<> sin, cos;
        get(sin, cos, rotations);
        return cos;
    }
};

constexpr auto sin_cos_list = SinCosList<>();

constexpr void rotate(Fixed<> &x, Fixed<> &y, Fixed<> rotations)
{
    Fixed<> sin, cos;
    sin_cos_list.get(sin, cos, rotations);
    auto new_x = x * cos - y * sin;
    auto new_y = x * sin + y * cos;
    x = new_x;
    y = new_y;
}

inline void write_fixed(Fixed<> v)
{
    write_hex_u32(floori(v));
    putchar('.');
    write_hex_u16(floori(fracf(v) * 0x10000));
}

template <typename T>
struct Vec2D
{
    typedef T element_type;
    T x, y;
    constexpr Vec2D() noexcept : x(), y()
    {
    }
    constexpr explicit Vec2D(T v) noexcept : x(v), y(v)
    {
    }
    constexpr Vec2D(T x, T y) noexcept : x(x), y(y)
    {
    }
    friend constexpr Vec2D operator+(Vec2D a, Vec2D b) noexcept
    {
        return Vec2D(a.x + b.x, a.y + b.y);
    }
    friend constexpr Vec2D operator-(Vec2D a, Vec2D b) noexcept
    {
        return Vec2D(a.x - b.x, a.y - b.y);
    }
    friend constexpr Vec2D operator*(T a, Vec2D b) noexcept
    {
        return Vec2D(a * b.x, a * b.y);
    }
    friend constexpr Vec2D operator*(Vec2D a, T b) noexcept
    {
        return Vec2D(a.x * b, a.y * b);
    }
    friend constexpr Vec2D operator/(Vec2D a, T b) noexcept
    {
        return Vec2D(a.x / b, a.y / b);
    }
    constexpr Vec2D &operator+=(Vec2D rt) noexcept
    {
        return *this = *this + rt;
    }
    constexpr Vec2D &operator-=(Vec2D rt) noexcept
    {
        return *this = *this - rt;
    }
    constexpr Vec2D &operator*=(T rt) noexcept
    {
        return *this = *this * rt;
    }
    constexpr Vec2D &operator/=(T rt) noexcept
    {
        return *this = *this / rt;
    }
};

constexpr Vec2D<Fixed<>> rotate(Vec2D<Fixed<>> v, Fixed<> rotations) noexcept
{
    rotate(v.x, v.y, rotations);
    return v;
}

constexpr void init_ray_cast_dimension(Fixed<> ray_direction,
                                       Fixed<> ray_start_position,
                                       std::int32_t current_position,
                                       Fixed<> &next_t,
                                       Fixed<> &step_t,
                                       std::int32_t &delta_position)
{
    if(ray_direction == 0)
        return;
    auto inverse_direction = 1 / ray_direction;
    step_t = abs(inverse_direction);
    std::int32_t target_position{};
    if(ray_direction < 0)
    {
        target_position = ceili(ray_start_position) - 1;
        delta_position = -1;
    }
    else
    {
        target_position = floori(ray_start_position) + 1;
        delta_position = 1;
    }
    next_t = (target_position - ray_start_position) * inverse_direction;
}

struct RayCaster
{
    Vec2D<Fixed<>> ray_start_position;
    Vec2D<Fixed<>> ray_direction;
    Vec2D<std::int32_t> current_position;
    Fixed<> current_t;
    Vec2D<Fixed<>> next_t;
    Vec2D<Fixed<>> step_t;
    Vec2D<std::int32_t> delta_position;
    int last_hit_dimension = -1;
    constexpr RayCaster(Vec2D<Fixed<>> ray_start_position, Vec2D<Fixed<>> ray_direction) noexcept
        : ray_start_position(ray_start_position),
          ray_direction(ray_direction),
          current_position(floori(ray_start_position.x), floori(ray_start_position.y)),
          current_t(Fixed<>::make(1)),
          next_t(0),
          step_t(0),
          delta_position(0)
    {
        init_ray_cast_dimension(ray_direction.x,
                                ray_start_position.x,
                                current_position.x,
                                next_t.x,
                                step_t.x,
                                delta_position.x);
        init_ray_cast_dimension(ray_direction.y,
                                ray_start_position.y,
                                current_position.y,
                                next_t.y,
                                step_t.y,
                                delta_position.y);
    }
    constexpr void step() noexcept
    {
        if(ray_direction.x != 0 && (ray_direction.y == 0 || next_t.x < next_t.y))
        {
            current_t = next_t.x;
            next_t.x += step_t.x;
            current_position.x += delta_position.x;
            last_hit_dimension = 0;
        }
        else if(ray_direction.y != 0)
        {
            current_t = next_t.y;
            next_t.y += step_t.y;
            current_position.y += delta_position.y;
            last_hit_dimension = 1;
        }
    }
};

int main()
{
    static std::uint8_t start_col[screen_x_size] = {}, end_col[screen_x_size] = {};
    static char col_color[screen_x_size] = {};
    constexpr std::size_t world_x_size = 16, world_z_size = 16;
    static const char world[world_x_size][world_z_size] = {
    // clang-format off
        {'|', '|', '|', '|', '|', '|', '|', '|', '|', '|', '|', '|', '|', '|', 'X', 'X'},
        {'|', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', '|', ' ', ' ', ' ', 'X'},
        {'|', ' ', '|', '|', '|', '|', '|', '|', '|', ' ', ' ', '|', ' ', ' ', ' ', 'X'},
        {'|', ' ', ' ', ' ', ' ', '|', ' ', ' ', '|', ' ', ' ', '|', ' ', '|', 'X', 'X'},
        {'|', ' ', ' ', ' ', ' ', '|', ' ', ' ', '|', ' ', ' ', '|', ' ', '|', '|', '|'},
        {'|', ' ', '|', ' ', ' ', '|', ' ', ' ', '|', ' ', ' ', '|', ' ', ' ', ' ', '|'},
        {'|', ' ', '|', ' ', ' ', '|', ' ', ' ', '|', ' ', ' ', '|', ' ', ' ', ' ', '|'},
        {'|', ' ', '|', ' ', ' ', ' ', ' ', ' ', '|', ' ', ' ', '|', '|', '|', ' ', '|'},
        {'|', ' ', '|', ' ', ' ', ' ', ' ', ' ', '|', ' ', ' ', '|', ' ', ' ', ' ', '|'},
        {'|', ' ', '|', '|', '|', '|', '|', '|', '|', ' ', ' ', '|', ' ', ' ', ' ', '|'},
        {'|', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', '|', ' ', ' ', ' ', '|'},
        {'|', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', '|', ' ', ' ', ' ', '|'},
        {'|', ' ', '|', '|', '|', '|', '|', '|', '|', ' ', ' ', '|', ' ', ' ', ' ', '|'},
        {'|', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', '|'},
        {'|', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', '|'},
        {'|', '|', '|', '|', '|', '|', '|', '|', '|', '|', '|', '|', '|', '|', '|', '|'},
    // clang-format on
    };
    Vec2D<Fixed<>> view_position(1.5, 1.5);
    Fixed<> view_angle(0);
    std::uint32_t flash_counter = 0;
    constexpr std::uint32_t flash_period = 10;
    while(true)
    {
        flash_counter++;
        if(flash_counter >= flash_period)
            flash_counter = 0;
        if(read_gpio() & switch_2_mask)
        {
            view_angle += 0.01;
            view_angle = fracf(view_angle);
        }
        if(read_gpio() & switch_3_mask)
        {
            Vec2D<Fixed<>> forward(0, 0.05);
            forward = rotate(forward, view_angle);
            auto new_view_position = view_position + forward;
            Vec2D<std::int32_t> new_block_position(floori(new_view_position.x),
                                                   floori(new_view_position.y));
#if 1
            auto block = world[new_block_position.x][new_block_position.y];
            if(block == ' ')
                view_position = new_view_position;
#else
            Fixed<> closest_distance(100);
            for(int dx = -1; dx <= 1; dx++)
            {
                for(int dy = -1; dy <= 1; dy++)
                {
                    auto block_position = new_block_position;
                    block_position.x += dx;
                    block_position.y += dy;
                    auto block = world[block_position.x][block_position.y];
                    if(block == ' ')
                        continue;
                    auto closest_position = new_view_position;
                    if(closest_position.x < block_position.x)
                        closest_position.x = block_position.x;
                    else if(closest_position.x > block_position.x + 1)
                        closest_position.x = block_position.x + 1;
                    if(closest_position.y < block_position.y)
                        closest_position.y = block_position.y;
                    else if(closest_position.y > block_position.y + 1)
                        closest_position.y = block_position.y + 1;
                    auto current_distance_x = abs(closest_position.x - block_position.x);
                    auto current_distance_y = abs(closest_position.y - block_position.y);
                    auto current_distance = current_distance_x;
                    if(current_distance < current_distance_y)
                        current_distance = current_distance_y;
                    if(current_distance < closest_distance)
                        closest_distance = current_distance;
                }
            }
            if(closest_distance >= 0.1)
                view_position = new_view_position;
#endif
        }
        for(std::size_t x = 0; x < screen_x_size; x++)
        {
            Vec2D<Fixed<>> ray_direction(
                (Fixed<>(x) + (0.5 - screen_x_size / 2.0)) * (2.0 / screen_x_size), 1);
            ray_direction = rotate(ray_direction, view_angle);
            RayCaster ray_caster(view_position, ray_direction);
            auto hit_block = world[ray_caster.current_position.x][ray_caster.current_position.y];
            while(hit_block == ' ')
            {
                ray_caster.step();
                hit_block = world[ray_caster.current_position.x][ray_caster.current_position.y];
            }
            constexpr Fixed<> max_height = 10;
            Fixed<> height = ray_caster.current_t != Fixed<>::make(1) ?
                                 1 / ray_caster.current_t :
                                 max_height;
            if(height > max_height)
                height = max_height;
            height *= screen_x_size / 2.0;
            auto iheight = roundi(height);
            if(iheight > static_cast<int>(screen_y_size))
                iheight = screen_y_size;
            else if(iheight < 0)
                iheight = 0;
            start_col[x] = screen_y_size / 2 - iheight / 2;
            end_col[x] = screen_y_size / 2 + (iheight + 1) / 2;
            col_color[x] = 0xB0;
            if(hit_block == 'X' && flash_counter >= flash_period / 2)
            {
                col_color[x] = '#';
                if(ray_caster.last_hit_dimension == 0)
                    col_color[x] = 'X';
            }
            else if(ray_caster.last_hit_dimension == 0)
            {
                col_color[x] = 0xB1;
            }
        }
        puts("\x1B[H");
        for(std::size_t y = 0; y < screen_y_size; y++)
        {
            for(std::size_t x = 0,
                            x_end = (y == screen_y_size - 1 ? screen_x_size - 1 : screen_x_size);
                x < x_end;
                x++)
            {
                if(y >= end_col[x])
                    putchar(0xB2);
                else if(y >= start_col[x])
                    putchar(col_color[x]);
                else
                    putchar(0x20);
            }
        }
    }
}
