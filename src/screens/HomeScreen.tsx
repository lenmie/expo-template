import React from 'react';
import styled from 'styled-components/native';

const Container = styled.View`
  flex: 1;
  justify-content: center;
  align-items: center;
  background-color: #fff;
`;

const StyledText = styled.Text`
  font-size: 24px;
  font-weight: bold;
`;

export const HomeScreen: React.FC = () => {
  return (
    <Container>
      <StyledText>MENEM LO HIZO</StyledText>
    </Container>
  );
};
