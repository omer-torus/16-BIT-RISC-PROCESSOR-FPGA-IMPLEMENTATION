/*
 * Minimal 8x8 Font ROM Module
 * 
 * Provides bitmap font for debug HUD character rendering.
 * Supports uppercase letters (A-Z), digits (0-9), and symbols.
 * 
 * Input: char_code (ASCII), row_index (0-7)
 * Output: row_pixels (8-bit bitmap)
 */

module font_min(
    input  wire [7:0] char_code,
    input  wire [2:0] row_index,
    output reg  [7:0] row_pixels
);

    always @(*) begin
        case (char_code)
            8'h20: row_pixels = 8'h00; // ' ' (space)

            // Punctuation and symbols
            8'h3A: begin // ':' (colon)
                case (row_index)
                    3'd2: row_pixels = 8'h18;
                    3'd5: row_pixels = 8'h18;
                    default: row_pixels = 8'h00;
                endcase
            end
            
            8'h2C: begin // ',' (comma)
                case (row_index)
                    3'd6: row_pixels = 8'h18;
                    3'd7: row_pixels = 8'h10;
                    default: row_pixels = 8'h00;
                endcase
            end
            
            8'h2D: begin // '-' (minus/dash)
                case (row_index)
                    3'd3: row_pixels = 8'h7E;
                    default: row_pixels = 8'h00;
                endcase
            end
            
            8'h2B: begin // '+' (plus)
                case (row_index)
                    3'd2: row_pixels = 8'h18;
                    3'd3: row_pixels = 8'h7E;
                    3'd4: row_pixels = 8'h18;
                    default: row_pixels = 8'h00;
                endcase
            end
            
            8'h28: begin // '(' (left paren)
                case (row_index)
                    3'd1: row_pixels = 8'h0C;
                    3'd2: row_pixels = 8'h18;
                    3'd3: row_pixels = 8'h18;
                    3'd4: row_pixels = 8'h18;
                    3'd5: row_pixels = 8'h0C;
                    default: row_pixels = 8'h00;
                endcase
            end
            
            8'h29: begin // ')' (right paren)
                case (row_index)
                    3'd1: row_pixels = 8'h30;
                    3'd2: row_pixels = 8'h18;
                    3'd3: row_pixels = 8'h18;
                    3'd4: row_pixels = 8'h18;
                    3'd5: row_pixels = 8'h30;
                    default: row_pixels = 8'h00;
                endcase
            end
            
            8'h23: begin // '#' (hash)
                case (row_index)
                    3'd1: row_pixels = 8'h24;
                    3'd2: row_pixels = 8'h7E;
                    3'd3: row_pixels = 8'h24;
                    3'd4: row_pixels = 8'h7E;
                    3'd5: row_pixels = 8'h24;
                    default: row_pixels = 8'h00;
                endcase
            end
            
            8'h3D: begin // '=' (equals)
                case (row_index)
                    3'd2: row_pixels = 8'h7E;
                    3'd4: row_pixels = 8'h7E;
                    default: row_pixels = 8'h00;
                endcase
            end
            
            8'h78: begin // 'x' (lowercase x)
                case (row_index)
                    3'd1: row_pixels = 8'h66;
                    3'd2: row_pixels = 8'h3C;
                    3'd3: row_pixels = 8'h18;
                    3'd4: row_pixels = 8'h3C;
                    3'd5: row_pixels = 8'h66;
                    default: row_pixels = 8'h00;
                endcase
            end

            // Digits 0-9
            8'h30: begin // '0'
                case(row_index)
                    3'd0: row_pixels = 8'h3C;
                    3'd1: row_pixels = 8'h66;
                    3'd2: row_pixels = 8'h6E;
                    3'd3: row_pixels = 8'h76;
                    3'd4: row_pixels = 8'h66;
                    3'd5: row_pixels = 8'h66;
                    3'd6: row_pixels = 8'h3C;
                    default: row_pixels = 8'h00;
                endcase
            end
            
            8'h31: begin // '1'
                case(row_index)
                    3'd0: row_pixels = 8'h18;
                    3'd1: row_pixels = 8'h38;
                    3'd2: row_pixels = 8'h18;
                    3'd3: row_pixels = 8'h18;
                    3'd4: row_pixels = 8'h18;
                    3'd5: row_pixels = 8'h18;
                    3'd6: row_pixels = 8'h7E;
                    default: row_pixels = 8'h00;
                endcase
            end
            
            // ... Digits 2-9
            8'h32: begin case(row_index) 3'd0:row_pixels=8'h3C;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h06;3'd3:row_pixels=8'h0C;3'd4:row_pixels=8'h30;3'd5:row_pixels=8'h60;3'd6:row_pixels=8'h7E;default:row_pixels=8'h00;endcase end
            8'h33: begin case(row_index) 3'd0:row_pixels=8'h3C;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h06;3'd3:row_pixels=8'h1C;3'd4:row_pixels=8'h06;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h3C;default:row_pixels=8'h00;endcase end
            8'h34: begin case(row_index) 3'd0:row_pixels=8'h0C;3'd1:row_pixels=8'h1C;3'd2:row_pixels=8'h3C;3'd3:row_pixels=8'h6C;3'd4:row_pixels=8'h7E;3'd5:row_pixels=8'h0C;3'd6:row_pixels=8'h0C;default:row_pixels=8'h00;endcase end
            8'h35: begin case(row_index) 3'd0:row_pixels=8'h7E;3'd1:row_pixels=8'h60;3'd2:row_pixels=8'h7C;3'd3:row_pixels=8'h06;3'd4:row_pixels=8'h06;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h3C;default:row_pixels=8'h00;endcase end
            8'h36: begin case(row_index) 3'd0:row_pixels=8'h1C;3'd1:row_pixels=8'h30;3'd2:row_pixels=8'h60;3'd3:row_pixels=8'h7C;3'd4:row_pixels=8'h66;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h3C;default:row_pixels=8'h00;endcase end
            8'h37: begin case(row_index) 3'd0:row_pixels=8'h7E;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h06;3'd3:row_pixels=8'h0C;3'd4:row_pixels=8'h18;3'd5:row_pixels=8'h18;3'd6:row_pixels=8'h18;default:row_pixels=8'h00;endcase end
            8'h38: begin case(row_index) 3'd0:row_pixels=8'h3C;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h66;3'd3:row_pixels=8'h3C;3'd4:row_pixels=8'h66;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h3C;default:row_pixels=8'h00;endcase end
            8'h39: begin case(row_index) 3'd0:row_pixels=8'h3C;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h66;3'd3:row_pixels=8'h3E;3'd4:row_pixels=8'h06;3'd5:row_pixels=8'h0C;3'd6:row_pixels=8'h38;default:row_pixels=8'h00;endcase end

            // Uppercase letters A-Z
            8'h41: begin case(row_index) 3'd0:row_pixels=8'h18;3'd1:row_pixels=8'h3C;3'd2:row_pixels=8'h66;3'd3:row_pixels=8'h66;3'd4:row_pixels=8'h7E;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h66;default:row_pixels=8'h00;endcase end
            8'h42: begin case(row_index) 3'd0:row_pixels=8'h7C;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h66;3'd3:row_pixels=8'h7C;3'd4:row_pixels=8'h66;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h7C;default:row_pixels=8'h00;endcase end
            8'h43: begin case(row_index) 3'd0:row_pixels=8'h3C;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h60;3'd3:row_pixels=8'h60;3'd4:row_pixels=8'h60;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h3C;default:row_pixels=8'h00;endcase end
            8'h44: begin case(row_index) 3'd0:row_pixels=8'h78;3'd1:row_pixels=8'h6C;3'd2:row_pixels=8'h66;3'd3:row_pixels=8'h66;3'd4:row_pixels=8'h66;3'd5:row_pixels=8'h6C;3'd6:row_pixels=8'h78;default:row_pixels=8'h00;endcase end
            8'h45: begin case(row_index) 3'd0:row_pixels=8'h7E;3'd1:row_pixels=8'h60;3'd2:row_pixels=8'h60;3'd3:row_pixels=8'h7C;3'd4:row_pixels=8'h60;3'd5:row_pixels=8'h60;3'd6:row_pixels=8'h7E;default:row_pixels=8'h00;endcase end
            8'h46: begin case(row_index) 3'd0:row_pixels=8'h7E;3'd1:row_pixels=8'h60;3'd2:row_pixels=8'h60;3'd3:row_pixels=8'h7C;3'd4:row_pixels=8'h60;3'd5:row_pixels=8'h60;3'd6:row_pixels=8'h60;default:row_pixels=8'h00;endcase end
            8'h47: begin case(row_index) 3'd0:row_pixels=8'h3C;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h60;3'd3:row_pixels=8'h6E;3'd4:row_pixels=8'h66;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h3C;default:row_pixels=8'h00;endcase end
            8'h48: begin case(row_index) 3'd0:row_pixels=8'h66;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h66;3'd3:row_pixels=8'h7E;3'd4:row_pixels=8'h66;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h66;default:row_pixels=8'h00;endcase end
            8'h49: begin case(row_index) 3'd0:row_pixels=8'h3C;3'd1:row_pixels=8'h18;3'd2:row_pixels=8'h18;3'd3:row_pixels=8'h18;3'd4:row_pixels=8'h18;3'd5:row_pixels=8'h18;3'd6:row_pixels=8'h3C;default:row_pixels=8'h00;endcase end
            8'h4A: begin case(row_index) 3'd0:row_pixels=8'h1E;3'd1:row_pixels=8'h0C;3'd2:row_pixels=8'h0C;3'd3:row_pixels=8'h0C;3'd4:row_pixels=8'h0C;3'd5:row_pixels=8'h6C;3'd6:row_pixels=8'h38;default:row_pixels=8'h00;endcase end
            8'h4B: begin case(row_index) 3'd0:row_pixels=8'h66;3'd1:row_pixels=8'h6C;3'd2:row_pixels=8'h78;3'd3:row_pixels=8'h70;3'd4:row_pixels=8'h78;3'd5:row_pixels=8'h6C;3'd6:row_pixels=8'h66;default:row_pixels=8'h00;endcase end
            8'h4C: begin case(row_index) 3'd0:row_pixels=8'h60;3'd1:row_pixels=8'h60;3'd2:row_pixels=8'h60;3'd3:row_pixels=8'h60;3'd4:row_pixels=8'h60;3'd5:row_pixels=8'h60;3'd6:row_pixels=8'h7E;default:row_pixels=8'h00;endcase end
            8'h4D: begin case(row_index) 3'd0:row_pixels=8'h63;3'd1:row_pixels=8'h77;3'd2:row_pixels=8'h7F;3'd3:row_pixels=8'h6B;3'd4:row_pixels=8'h63;3'd5:row_pixels=8'h63;3'd6:row_pixels=8'h63;default:row_pixels=8'h00;endcase end
            8'h4E: begin case(row_index) 3'd0:row_pixels=8'h66;3'd1:row_pixels=8'h76;3'd2:row_pixels=8'h7E;3'd3:row_pixels=8'h7E;3'd4:row_pixels=8'h6E;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h66;default:row_pixels=8'h00;endcase end
            8'h4F: begin case(row_index) 3'd0:row_pixels=8'h3C;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h66;3'd3:row_pixels=8'h66;3'd4:row_pixels=8'h66;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h3C;default:row_pixels=8'h00;endcase end
            8'h50: begin case(row_index) 3'd0:row_pixels=8'h7C;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h66;3'd3:row_pixels=8'h7C;3'd4:row_pixels=8'h60;3'd5:row_pixels=8'h60;3'd6:row_pixels=8'h60;default:row_pixels=8'h00;endcase end
            8'h51: begin case(row_index) 3'd0:row_pixels=8'h3C;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h66;3'd3:row_pixels=8'h66;3'd4:row_pixels=8'h6E;3'd5:row_pixels=8'h3C;3'd6:row_pixels=8'h0E;default:row_pixels=8'h00;endcase end
            8'h52: begin case(row_index) 3'd0:row_pixels=8'h7C;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h66;3'd3:row_pixels=8'h7C;3'd4:row_pixels=8'h6C;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h66;default:row_pixels=8'h00;endcase end
            8'h53: begin case(row_index) 3'd0:row_pixels=8'h3C;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h60;3'd3:row_pixels=8'h3C;3'd4:row_pixels=8'h06;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h3C;default:row_pixels=8'h00;endcase end
            8'h54: begin case(row_index) 3'd0:row_pixels=8'h7E;3'd1:row_pixels=8'h18;3'd2:row_pixels=8'h18;3'd3:row_pixels=8'h18;3'd4:row_pixels=8'h18;3'd5:row_pixels=8'h18;3'd6:row_pixels=8'h18;default:row_pixels=8'h00;endcase end
            8'h55: begin case(row_index) 3'd0:row_pixels=8'h66;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h66;3'd3:row_pixels=8'h66;3'd4:row_pixels=8'h66;3'd5:row_pixels=8'h66;3'd6:row_pixels=8'h3C;default:row_pixels=8'h00;endcase end
            8'h56: begin case(row_index) 3'd0:row_pixels=8'h66;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h66;3'd3:row_pixels=8'h66;3'd4:row_pixels=8'h3C;3'd5:row_pixels=8'h3C;3'd6:row_pixels=8'h18;default:row_pixels=8'h00;endcase end
            8'h57: begin case(row_index) 3'd0:row_pixels=8'h63;3'd1:row_pixels=8'h63;3'd2:row_pixels=8'h63;3'd3:row_pixels=8'h6B;3'd4:row_pixels=8'h7F;3'd5:row_pixels=8'h77;3'd6:row_pixels=8'h63;default:row_pixels=8'h00;endcase end
            8'h58: begin case(row_index) 3'd0:row_pixels=8'h66;3'd1:row_pixels=8'h3C;3'd2:row_pixels=8'h18;3'd3:row_pixels=8'h18;3'd4:row_pixels=8'h18;3'd5:row_pixels=8'h3C;3'd6:row_pixels=8'h66;default:row_pixels=8'h00;endcase end
            8'h59: begin case(row_index) 3'd0:row_pixels=8'h66;3'd1:row_pixels=8'h66;3'd2:row_pixels=8'h3C;3'd3:row_pixels=8'h18;3'd4:row_pixels=8'h18;3'd5:row_pixels=8'h18;3'd6:row_pixels=8'h18;default:row_pixels=8'h00;endcase end
            8'h5A: begin case(row_index) 3'd0:row_pixels=8'h7E;3'd1:row_pixels=8'h06;3'd2:row_pixels=8'h0C;3'd3:row_pixels=8'h18;3'd4:row_pixels=8'h30;3'd5:row_pixels=8'h60;3'd6:row_pixels=8'h7E;default:row_pixels=8'h00;endcase end
            
            default: row_pixels = 8'h00; // Unknown character - blank
        endcase
    end
endmodule
